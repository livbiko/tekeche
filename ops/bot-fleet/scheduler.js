// Phase 4 of the 20-day bot QA fleet: the window scheduler. Decides which of
// the 35 identities are "driving" vs "requesting rides" right now, and
// reconciles that against the actually-running driver-bot.js/passenger-bot.js
// child processes — only restarting the ones whose role actually changed.
//
// Midnight-06:00 is undefined in the role-play spec — the whole fleet goes
// idle during that gap (explicit decision, not a default).
//
// Usage:
//   node scheduler.js            # runs for real, spawns/kills bot processes
//   node scheduler.js --dry-run  # logs decisions only, spawns nothing

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const { loadManifest, log } = require('./lib');

const DRY_RUN = process.argv.includes('--dry-run');
const RUN_DAYS = 20;
const TICK_MS = 60 * 1000;
const LOG_DIR = path.join(__dirname, 'logs');
const STATE_PATH = path.join(__dirname, 'fleet-state.json');
const STOP_PATH = path.join(__dirname, 'STOP');

if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

// 5 role-play windows exactly as specified. Hours outside all of these
// (00:00-06:00) are the explicit idle gap.
const WINDOWS = [
  { start: 6,  end: 10, passenger: 40, moto: 5,  standard: 22, comfort: 10, xl: 6, woyo: 17 },
  { start: 10, end: 14, passenger: 48, moto: 7,  standard: 20, comfort: 8,  xl: 5, woyo: 12 },
  { start: 14, end: 18, passenger: 35, moto: 11, standard: 30, comfort: 6,  xl: 6, woyo: 12 },
  { start: 18, end: 22, passenger: 50, moto: 8,  standard: 25, comfort: 5,  xl: 4, woyo: 8  },
  { start: 22, end: 24, passenger: 20, moto: 2,  standard: 35, comfort: 15, xl: 8, woyo: 20 },
];

function currentWindow(date = new Date()) {
  const h = date.getHours();
  return WINDOWS.find(w => h >= w.start && h < w.end) || null; // null => idle gap
}

// Largest-remainder (Hare quota) apportionment: turns percentages into
// integer headcounts that always sum to exactly `total`, rather than
// independently-rounded buckets that can overshoot/undershoot 35.
function apportion(total, weights) {
  const keys = Object.keys(weights);
  const raw = keys.map(k => (weights[k] / 100) * total);
  const base = raw.map(Math.floor);
  const assigned = base.reduce((a, b) => a + b, 0);
  const remainders = keys.map((k, i) => ({ k, rem: raw[i] - base[i] }))
    .sort((a, b) => b.rem - a.rem);
  const result = {};
  keys.forEach((k, i) => { result[k] = base[i]; });
  let remaining = total - assigned;
  for (let j = 0; j < remaining; j++) result[remainders[j % remainders.length].k]++;
  return result;
}

function shuffled(arr, seed) {
  const a = arr.slice();
  let s = seed;
  const rand = () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; };
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// Decides which specific identity indices drive (and of what type) vs which
// act as passengers this window. Pools are capped at what Phase 1 actually
// provisioned; any apportioned overflow for a vehicle type falls back to
// the passenger bucket (unlimited — any identity's User side can request).
function computeAssignment(manifest, window, seed) {
  if (!window) return { drivers: new Map(), passengers: new Set(manifest.map(m => m.index)) };

  // window carries start/end alongside the percentage weights — strip them
  // before apportioning, or they get treated as two extra phantom buckets
  // and silently steal share from the real ones.
  const { start, end, ...weights } = window;
  const counts = apportion(35, weights);
  const pools = {
    moto:     manifest.filter(m => m.vehicleType === 'moto'),
    standard: manifest.filter(m => m.vehicleType === 'standard' && !m.woyo),
    comfort:  manifest.filter(m => m.vehicleType === 'comfort'),
    xl:       manifest.filter(m => m.vehicleType === 'xl'),
    woyo:     manifest.filter(m => m.woyo),
  };

  const drivers = new Map(); // index -> bucket label
  let overflowToPassenger = 0;
  for (const bucket of ['moto', 'standard', 'comfort', 'xl', 'woyo']) {
    const want = counts[bucket];
    const pool = shuffled(pools[bucket], seed + bucket.length);
    const take = Math.min(want, pool.length);
    overflowToPassenger += want - take;
    for (let i = 0; i < take; i++) drivers.set(pool[i].index, bucket);
  }

  const passengers = new Set();
  for (const m of manifest) if (!drivers.has(m.index)) passengers.add(m.index);

  return { drivers, passengers, targetPassengerCount: counts.passenger + overflowToPassenger };
}

// ── Process management ──────────────────────────────────────────────────
const running = new Map(); // index -> { proc, role }

function stopBot(index) {
  const entry = running.get(index);
  if (!entry) return;
  log('scheduler', `stopping ${entry.role} bot #${index}`);
  if (!DRY_RUN) entry.proc.kill('SIGTERM');
  running.delete(index);
}

function startBot(index, role, manifestEntry) {
  const script = role === 'driver' ? 'driver-bot.js' : 'passenger-bot.js';
  log('scheduler', `starting ${role} bot #${index} (${manifestEntry.name})`);
  if (DRY_RUN) { running.set(index, { proc: null, role }); return; }

  const logPath = path.join(LOG_DIR, `bot-${String(index).padStart(2, '0')}.log`);
  const out = fs.openSync(logPath, 'a');
  const proc = spawn('node', [path.join(__dirname, script), String(index)], {
    cwd: __dirname,
    stdio: ['ignore', out, out],
  });
  proc.on('exit', (code) => {
    log('scheduler', `bot #${index} (${role}) exited code=${code}`);
    if (running.get(index)?.proc === proc) running.delete(index);
  });
  running.set(index, { proc, role });
}

function reconcile(manifest, assignment) {
  const desired = new Map(); // index -> 'driver' | 'passenger'
  for (const index of assignment.drivers.keys()) desired.set(index, 'driver');
  for (const index of assignment.passengers) desired.set(index, 'passenger');

  // Stop anything whose desired role changed (or that's no longer active at all).
  for (const [index, entry] of running) {
    if (desired.get(index) !== entry.role) stopBot(index);
  }
  // Start anything newly desired that isn't already running with that role,
  // staggered so 35 processes don't all connect in the same instant.
  let delay = 0;
  for (const [index, role] of desired) {
    if (running.has(index)) continue;
    const manifestEntry = manifest.find(m => m.index === index);
    setTimeout(() => startBot(index, role, manifestEntry), delay);
    delay += 1500;
  }
}

function stopAll() {
  log('scheduler', `stopping all ${running.size} active bots`);
  for (const index of Array.from(running.keys())) stopBot(index);
}

// ── State (survives scheduler restarts under PM2) ───────────────────────
function loadOrInitState() {
  if (fs.existsSync(STATE_PATH)) return JSON.parse(fs.readFileSync(STATE_PATH, 'utf8'));
  const state = { startedAt: new Date().toISOString() };
  fs.writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
  return state;
}

// ── Main loop ─────────────────────────────────────────────────────────────
function main() {
  const manifest = loadManifest();
  const state = loadOrInitState();
  const startedAt = new Date(state.startedAt);
  const endsAt = new Date(startedAt.getTime() + RUN_DAYS * 24 * 60 * 60 * 1000);
  log('scheduler', `${DRY_RUN ? '[DRY RUN] ' : ''}fleet started ${startedAt.toISOString()}, ends ${endsAt.toISOString()}`);

  let lastWindowKey = null;

  function tick() {
    if (fs.existsSync(STOP_PATH)) {
      log('scheduler', 'STOP file present — shutting down fleet');
      stopAll();
      process.exit(0);
    }
    if (Date.now() >= endsAt.getTime()) {
      log('scheduler', '20-day run complete — shutting down fleet');
      stopAll();
      process.exit(0);
    }

    const now = new Date();
    const win = currentWindow(now);
    const windowKey = win ? `${win.start}-${win.end}` : 'idle';

    if (windowKey !== lastWindowKey) {
      lastWindowKey = windowKey;
      const seed = Math.floor(now.getTime() / TICK_MS);
      const assignment = computeAssignment(manifest, win, seed);
      if (win) {
        log('scheduler', `window ${win.start}:00-${win.end}:00 → ${assignment.drivers.size} driving, ${assignment.passengers.size} passenger-mode`);
      } else {
        log('scheduler', 'entering idle gap (00:00-06:00) — all bots offline');
      }
      reconcile(manifest, assignment);
    }
  }

  tick();
  setInterval(tick, TICK_MS);
}

process.on('SIGINT', () => { stopAll(); process.exit(0); });
process.on('SIGTERM', () => { stopAll(); process.exit(0); });

main();
