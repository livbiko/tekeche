#!/usr/bin/env node
'use strict';

/**
 * mongo-rs-watchdog
 *
 * Removes rs0 members from the replica set config once they've been
 * unreachable for DOWN_THRESHOLD_MS, and re-adds them once they've been
 * reachable again for UP_THRESHOLD_MS.
 *
 * Why this exists: during a 2026-08-01 combined BikoDC+BikoDC1 outage drill,
 * mongod on the OCI standby kept retrying the two dead on-prem members every
 * cycle, each attempt hanging ~20s before failing (HostUnreachable). That
 * reconnect storm starved the standby's own connection/network capacity even
 * though it had already become a healthy primary within 12s -- the app
 * couldn't get a local connection to its own database for the full ~36min
 * outage. Evicting a member that's genuinely gone stops mongod from wasting
 * capacity retrying it.
 *
 * Only ever touches the two on-prem data members (WATCHED_HOSTS below) --
 * never arbiters, never the standby itself. Every reconfig is logged.
 */

const { MongoClient } = require('mongodb');
const fs = require('fs');
const path = require('path');

const ADMIN_URI = process.env.MONGO_ADMIN_URI;
const WATCHED_HOSTS = (process.env.WATCHED_HOSTS || '192.168.1.101:27017,192.168.1.102:27017')
  .split(',')
  .map((h) => h.trim())
  .filter(Boolean);
const DOWN_THRESHOLD_MS = Number(process.env.DOWN_THRESHOLD_MS || 120000);
const UP_THRESHOLD_MS = Number(process.env.UP_THRESHOLD_MS || 60000);
const POLL_INTERVAL_MS = Number(process.env.POLL_INTERVAL_MS || 15000);
const PROBE_TIMEOUT_MS = Number(process.env.PROBE_TIMEOUT_MS || 3000);
const MIN_REMAINING_MEMBERS = Number(process.env.MIN_REMAINING_MEMBERS || 3);
const STATE_FILE = process.env.STATE_FILE || '/opt/mongo-rs-watchdog/state.json';
const KILL_SWITCH_FILE = process.env.KILL_SWITCH_FILE || '/opt/mongo-rs-watchdog/DISABLED';

if (!ADMIN_URI) {
  console.error('MONGO_ADMIN_URI is required (needs clusterManager role on admin db)');
  process.exit(1);
}

function log(level, msg, extra) {
  const line = `${new Date().toISOString()} [${level}] ${msg}${extra ? ' ' + JSON.stringify(extra) : ''}`;
  console.log(line);
}

function loadState() {
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  } catch {
    return {};
  }
}

function saveState(state) {
  fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

async function probeHost(hostPort) {
  const [host, port] = hostPort.split(':');
  const client = new MongoClient(`mongodb://${host}:${port}/?directConnection=true`, {
    serverSelectionTimeoutMS: PROBE_TIMEOUT_MS,
    connectTimeoutMS: PROBE_TIMEOUT_MS,
  });
  try {
    await client.connect();
    await client.db('admin').command({ ping: 1 });
    return true;
  } catch {
    return false;
  } finally {
    await client.close().catch(() => {});
  }
}

async function getPrimaryStatus(adminClient) {
  const status = await adminClient.db('admin').command({ replSetGetStatus: 1 });
  const primary = status.members.find((m) => m.stateStr === 'PRIMARY');
  return { hasPrimary: !!primary, status };
}

async function removeMember(adminClient, hostPort, state) {
  const conf = await adminClient.db('admin').command({ replSetGetConfig: 1 });
  const cfg = conf.config;
  const member = cfg.members.find((m) => m.host === hostPort);
  if (!member) return; // already removed

  if (cfg.members.length - 1 < MIN_REMAINING_MEMBERS) {
    log('WARN', 'refusing to remove member, would drop below MIN_REMAINING_MEMBERS', { hostPort, remaining: cfg.members.length - 1 });
    return;
  }

  state[hostPort] = state[hostPort] || {};
  state[hostPort].savedMemberConfig = member; // snapshot for exact re-add later

  cfg.members = cfg.members.filter((m) => m.host !== hostPort);
  cfg.version += 1;

  await adminClient.db('admin').command({ replSetReconfig: cfg });
  log('WARN', 'removed unreachable member from rs0', { hostPort, downForMs: Date.now() - state[hostPort].downSince });
}

async function readdMember(adminClient, hostPort, state) {
  const saved = state[hostPort] && state[hostPort].savedMemberConfig;
  if (!saved) {
    log('WARN', 'cannot re-add, no saved member config on file', { hostPort });
    return;
  }

  const conf = await adminClient.db('admin').command({ replSetGetConfig: 1 });
  const cfg = conf.config;
  if (cfg.members.some((m) => m.host === hostPort)) return; // already back in

  const usedIds = new Set(cfg.members.map((m) => m._id));
  const restored = { ...saved };
  if (usedIds.has(restored._id)) {
    restored._id = Math.max(...cfg.members.map((m) => m._id)) + 1;
  }

  cfg.members.push(restored);
  cfg.version += 1;

  await adminClient.db('admin').command({ replSetReconfig: cfg });
  log('WARN', 're-added recovered member to rs0', { hostPort, upForMs: Date.now() - state[hostPort].upSince });
}

async function tick(adminClient, state) {
  const killSwitchActive = fs.existsSync(KILL_SWITCH_FILE);
  const now = Date.now();

  const results = await Promise.all(WATCHED_HOSTS.map(async (h) => [h, await probeHost(h)]));

  let actionTakenThisTick = false;

  for (const [hostPort, reachable] of results) {
    state[hostPort] = state[hostPort] || {};
    const s = state[hostPort];

    if (reachable) {
      if (s.downSince) delete s.downSince;
      if (!s.upSince) s.upSince = now;
    } else {
      if (s.upSince) delete s.upSince;
      if (!s.downSince) s.downSince = now;
    }

    log('INFO', 'probe result', { hostPort, reachable });
  }

  if (killSwitchActive) {
    log('INFO', 'kill switch active, monitoring only, no reconfig actions');
    saveState(state);
    return;
  }

  let primaryInfo;
  try {
    primaryInfo = await getPrimaryStatus(adminClient);
  } catch (err) {
    log('ERROR', 'could not read replSetGetStatus, skipping this tick', { error: String(err) });
    saveState(state);
    return;
  }
  if (!primaryInfo.hasPrimary) {
    log('WARN', 'no primary visible right now, skipping reconfig actions this tick');
    saveState(state);
    return;
  }

  const confResult = await adminClient.db('admin').command({ replSetGetConfig: 1 });
  const currentHosts = new Set(confResult.config.members.map((m) => m.host));

  for (const hostPort of WATCHED_HOSTS) {
    if (actionTakenThisTick) break; // one reconfig action per tick, keep changes serialized
    const s = state[hostPort];
    const inConfig = currentHosts.has(hostPort);

    if (inConfig && s.downSince && now - s.downSince >= DOWN_THRESHOLD_MS) {
      await removeMember(adminClient, hostPort, state);
      actionTakenThisTick = true;
    } else if (!inConfig && s.upSince && now - s.upSince >= UP_THRESHOLD_MS) {
      await readdMember(adminClient, hostPort, state);
      actionTakenThisTick = true;
    }
  }

  saveState(state);
}

async function main() {
  const adminClient = new MongoClient(ADMIN_URI, {
    serverSelectionTimeoutMS: 10000,
  });
  await adminClient.connect();
  log('INFO', 'mongo-rs-watchdog started', { WATCHED_HOSTS, DOWN_THRESHOLD_MS, UP_THRESHOLD_MS, POLL_INTERVAL_MS });

  const state = loadState();

  const loop = async () => {
    try {
      await tick(adminClient, state);
    } catch (err) {
      log('ERROR', 'tick failed', { error: String(err && err.stack) });
    }
    setTimeout(loop, POLL_INTERVAL_MS);
  };

  await loop();
}

process.on('SIGTERM', () => process.exit(0));
process.on('SIGINT', () => process.exit(0));

main().catch((err) => {
  log('ERROR', 'fatal startup error', { error: String(err && err.stack) });
  process.exit(1);
});
