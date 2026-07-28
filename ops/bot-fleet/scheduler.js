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
const SWEEP_MS = 5 * 60 * 1000;
const STALE_TRIP_MS = 30 * 60 * 1000; // past driver-bot's 25-min max travel time, plus margin
const STOP_GRACE_MS = 5000; // SIGTERM grace period before SIGKILL fallback
const LIVENESS_SWEEP_MS = 5 * 60 * 1000;
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

// Returns a Promise that resolves once the process has actually exited (or a
// grace period elapses and we SIGKILL it) — NOT just once SIGTERM was sent.
// Found live: a driver bot whose socket died silently left the Node process
// itself running forever, invisible to reconcile() because the old code
// deleted it from `running` the instant SIGTERM was sent, before confirming
// anything actually died. That let a zombie and its replacement coexist,
// both driving the same identity, for hours.
function stopBot(index) {
  const entry = running.get(index);
  if (!entry) return Promise.resolve();
  log('scheduler', `stopping ${entry.role} bot #${index}`);
  running.delete(index);
  if (DRY_RUN || !entry.proc) return Promise.resolve();

  return new Promise((resolve) => {
    let settled = false;
    const finish = () => { if (!settled) { settled = true; resolve(); } };
    entry.proc.once('exit', finish);
    entry.proc.kill('SIGTERM');
    setTimeout(() => {
      if (!settled) {
        log('scheduler', `bot #${index} did not exit within ${STOP_GRACE_MS / 1000}s of SIGTERM — forcing SIGKILL`);
        try { entry.proc.kill('SIGKILL'); } catch {}
        finish();
      }
    }, STOP_GRACE_MS);
  });
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

async function reconcile(manifest, assignment) {
  const desired = new Map(); // index -> 'driver' | 'passenger'
  for (const index of assignment.drivers.keys()) desired.set(index, 'driver');
  for (const index of assignment.passengers) desired.set(index, 'passenger');

  // Stop anything whose desired role changed (or that's no longer active at
  // all) and WAIT for confirmed termination before starting replacements —
  // otherwise a slow-to-die old process and its fresh replacement can run
  // the same identity simultaneously.
  const stopPromises = [];
  for (const [index, entry] of running) {
    if (desired.get(index) !== entry.role) stopPromises.push(stopBot(index));
  }
  await Promise.all(stopPromises);

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
  return Promise.all(Array.from(running.keys()).map(stopBot));
}

// ── Orphaned-trip sweep ───────────────────────────────────────────────────
// Backstop for driver-bot.js's own startup recovery: that only fires if the
// SAME identity happens to come back as a driver on its next process start.
// If a role-reassignment moves it to passenger instead (exactly what
// happened live: a driver bot got killed mid-trip on a scheduler restart,
// and the fresh reconcile() reassigned that identity to passenger — no
// driver-bot instance for it ever ran again to trigger recovery), the trip
// is orphaned forever with nothing role-specific to catch it. This sweep is
// role-independent: it directly resolves any synthetic trip stuck past a
// generous staleness threshold, regardless of which bot (if any) currently
// owns that identity.
let mongoosePromise = null;
function getMongoose() {
  if (!mongoosePromise) {
    const API_DIR = 'C:/inetpub/wwwroot/tekeche/tekeche-api';
    const mongoose = require(path.join(API_DIR, 'node_modules/mongoose'));
    const envLine = fs.readFileSync(path.join(API_DIR, '.env'), 'utf8').split(/\r?\n/).find(l => l.startsWith('MONGODB_URI='));
    mongoosePromise = mongoose.connect(envLine.slice('MONGODB_URI='.length)).then(() => ({
      Trip: require(path.join(API_DIR, 'src/models/Trip')),
      Driver: require(path.join(API_DIR, 'src/models/Driver')),
    }));
  }
  return mongoosePromise;
}

async function sweepOrphanedTrips() {
  if (DRY_RUN) return;
  try {
    const { Trip, Driver } = await getMongoose();
    const stale = await Trip.find({
      isSynthetic: true,
      status: { $in: ['accepted', 'driver_arriving', 'in_progress'] },
      updatedAt: { $lt: new Date(Date.now() - STALE_TRIP_MS) },
    });
    if (!stale.length) return;
    log('scheduler', `sweep: found ${stale.length} orphaned trip(s)`);
    for (const trip of stale) {
      await Trip.findByIdAndUpdate(trip._id, {
        status: 'cancelled', cancelledBy: 'system',
        cancelReason: 'Orphaned trip swept by scheduler (stale past travel-time cap)',
      });
      if (trip.driver) await Driver.findByIdAndUpdate(trip.driver, { isAvailable: true });
      log('scheduler', `sweep: cancelled orphaned trip=${trip._id} (was ${trip.status})`);
    }
  } catch (err) {
    log('scheduler', `sweep error: ${err.message}`);
  }
}

// ── Dead-driver liveness sweep ────────────────────────────────────────────
// Found live: a driver bot's socket died (network blip) but the Node process
// itself never exited — nothing in driver-bot.js causes it to exit on
// repeated reconnect failure, and the scheduler only reacts to an actual
// 'exit' event, so a process that goes silent-but-alive was invisible
// indefinitely. This directly checks the DB's isOnline flag (managed by the
// server itself on socket connect/disconnect) against what we're currently
// tracking as an active driver, and force-restarts any mismatch. A restart
// triggered on a driver that was already mid-reconnect is a harmless no-op
// cost; leaving a real zombie running silently for hours is not.
async function sweepDeadDrivers(manifest) {
  if (DRY_RUN) return;
  try {
    const { Driver } = await getMongoose();
    for (const [index, entry] of Array.from(running.entries())) {
      if (entry.role !== 'driver') continue;
      const manifestEntry = manifest.find(m => m.index === index);
      const d = await Driver.findById(manifestEntry.driverId).select('isOnline').lean();
      if (d && !d.isOnline) {
        log('scheduler', `liveness: bot #${index} (driver) shows isOnline=false while tracked as active — restarting`);
        await stopBot(index);
        startBot(index, 'driver', manifestEntry);
      }
    }
  } catch (err) {
    log('scheduler', `liveness sweep error: ${err.message}`);
  }
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
      stopAll().then(() => process.exit(0));
      return;
    }
    if (Date.now() >= endsAt.getTime()) {
      log('scheduler', '20-day run complete — shutting down fleet');
      stopAll().then(() => process.exit(0));
      return;
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

  sweepOrphanedTrips().catch(e => log('scheduler', `sweep error: ${e.message}`));
  setInterval(() => sweepOrphanedTrips().catch(e => log('scheduler', `sweep error: ${e.message}`)), SWEEP_MS);

  setInterval(() => sweepDeadDrivers(manifest).catch(e => log('scheduler', `liveness sweep error: ${e.message}`)), LIVENESS_SWEEP_MS);
}

process.on('SIGINT', () => { stopAll().then(() => process.exit(0)); });
process.on('SIGTERM', () => { stopAll().then(() => process.exit(0)); });

main();
