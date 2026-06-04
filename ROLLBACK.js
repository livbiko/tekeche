#!/usr/bin/env node
/**
 * Tekeche Rollback Tool
 * Usage:
 *   node ROLLBACK.js status              — show current deployed state
 *   node ROLLBACK.js api                 — list API snapshots, pick one to restore
 *   node ROLLBACK.js api <tag|commit>    — restore API to specific tag or commit
 *   node ROLLBACK.js ota                 — list OTA updates, pick one to restore
 *   node ROLLBACK.js ota <group-id>      — restore OTA to specific update group
 *   node ROLLBACK.js db                  — list DB backups, pick one to restore
 *   node ROLLBACK.js db <backup-name>    — restore DB from specific backup folder
 */

const { execSync, spawnSync } = require('child_process');
const fs   = require('fs');
const path = require('path');
const zlib = require('zlib');

const API_DIR     = 'C:\\inetpub\\wwwroot\\tekeche\\tekeche-api';
const MOBILE_DIR  = 'C:\\inetpub\\wwwroot\\tekeche\\tekeche-mobile';
const BACKUP_DIR  = 'C:\\backups\\tekeche';
const MONGODB_URI = require(path.join(API_DIR, 'node_modules', 'dotenv')).config({ path: path.join(API_DIR, '.env') }).parsed?.MONGODB_URI;

const run = (cmd, cwd) => execSync(cmd, { cwd, encoding: 'utf8', stdio: ['pipe','pipe','pipe'] }).trim();
const print = (...a) => console.log(...a);
const hr = () => print('\n' + '─'.repeat(60));

// ─── STATUS ──────────────────────────────────────────────────────────────────
function status() {
  hr();
  print('TEKECHE — CURRENT DEPLOYED STATE');
  hr();

  // API
  try {
    const apiHash    = run('git rev-parse --short HEAD', API_DIR);
    const apiMsg     = run('git log -1 --pretty=%s', API_DIR);
    const apiDate    = run('git log -1 --pretty=%ci', API_DIR);
    const pm2Status  = run('pm2 jlist', API_DIR);
    const procs      = JSON.parse(pm2Status).filter(p => p.name === 'tekeche-api');
    const apiHealth  = procs.every(p => p.pm2_env.status === 'online') ? '✓ online' : '✗ offline';
    print(`\nAPI`);
    print(`  Commit : ${apiHash} — ${apiMsg}`);
    print(`  Date   : ${apiDate}`);
    print(`  PM2    : ${apiHealth} (${procs.length} instance${procs.length !== 1 ? 's' : ''})`);
    print(`  Tags   : ${run('git tag -l', API_DIR).split('\n').filter(Boolean).join(', ') || 'none'}`);
  } catch (e) { print(`\nAPI  ERROR: ${e.message}`); }

  // Mobile OTA
  try {
    const mobileHash = run('git rev-parse --short HEAD', MOBILE_DIR);
    const mobileMsg  = run('git log -1 --pretty=%s', MOBILE_DIR);
    print(`\nMOBILE`);
    print(`  Commit : ${mobileHash} — ${mobileMsg}`);
    print(`  Tags   : ${run('git tag -l', MOBILE_DIR).split('\n').filter(Boolean).join(', ') || 'none'}`);
    const otaList = run('eas update:list --branch production --limit 3 --non-interactive', MOBILE_DIR);
    print(`  OTA    : (latest 3 below)`);
    otaList.split('\n').filter(l => /Message|Group ID/.test(l)).forEach(l => print('           ' + l.trim()));
  } catch (e) { print(`\nMOBILE  ERROR: ${e.message}`); }

  // DB backups
  try {
    const backups = fs.readdirSync(BACKUP_DIR).sort().reverse().slice(0, 5);
    print(`\nDB BACKUPS (latest 5)`);
    backups.forEach(b => {
      const stat = fs.statSync(path.join(BACKUP_DIR, b));
      print(`  ${b}  (${stat.mtime.toLocaleDateString('fr-FR')})`);
    });
  } catch (e) { print(`\nDB  ERROR: ${e.message}`); }

  hr();
}

// ─── API ROLLBACK ─────────────────────────────────────────────────────────────
function rollbackApi(target) {
  hr();
  if (!target) {
    print('Available API rollback points:\n');
    const tags = run('git tag -l', API_DIR).split('\n').filter(Boolean);
    const commits = run('git log --oneline -8', API_DIR).split('\n');
    print('TAGS:');
    tags.forEach((t, i) => print(`  [${i + 1}] ${t}`));
    print('\nRECENT COMMITS:');
    commits.forEach((c, i) => print(`  [${tags.length + i + 1}] ${c}`));
    print('\nRun:  node ROLLBACK.js api <tag-or-commit-hash>');
    return;
  }

  print(`\nRolling back API to: ${target}`);
  print('Step 1/3  Restoring src/ from ' + target);
  run(`git checkout ${target} -- src/`, API_DIR);

  print('Step 2/3  Reloading PM2 (zero-downtime)');
  run('pm2 reload tekeche-api', API_DIR);

  print('Step 3/3  Verifying health');
  try {
    const { execSync: ex } = require('child_process');
    const health = ex('node -e "require(\'https\').get(\'https://api.tekeche.com/health\', r=>{let d=\'\';r.on(\'data\',c=>d+=c);r.on(\'end\',()=>console.log(d));})"', { encoding: 'utf8', timeout: 10000 });
    print('Health: ' + health.trim());
  } catch { print('Health check skipped (network)'); }

  print(`\n✓ API rolled back to ${target}`);
  print(`  To undo: node ROLLBACK.js api main`);
  hr();
}

// ─── OTA ROLLBACK ─────────────────────────────────────────────────────────────
function rollbackOta(groupId) {
  hr();
  if (!groupId) {
    print('Recent OTA update groups:\n');
    try {
      const list = run('eas update:list --branch production --limit 8 --non-interactive', MOBILE_DIR);
      list.split('\n').filter(l => /Message|Group ID/.test(l)).forEach(l => print('  ' + l.trim()));
    } catch (e) { print('  (could not fetch list: ' + e.message + ')'); }
    print('\nRun:  node ROLLBACK.js ota <group-id>');
    return;
  }

  print(`\nRepublishing OTA update group: ${groupId}`);
  print('Pushing previous update to production channel...');
  const result = run(
    `eas update:republish --group ${groupId} --channel production --non-interactive`,
    MOBILE_DIR
  );
  print(result);
  print(`\n✓ OTA rolled back to group ${groupId}`);
  print('  Users will receive the previous update on next app launch.');
  hr();
}

// ─── DB RESTORE ───────────────────────────────────────────────────────────────
async function restoreDb(backupName) {
  hr();

  const backups = fs.readdirSync(BACKUP_DIR).sort().reverse();

  if (!backupName) {
    print('Available DB backups:\n');
    backups.forEach((b, i) => {
      const dir = path.join(BACKUP_DIR, b);
      const files = fs.readdirSync(dir);
      print(`  [${i + 1}] ${b}  (${files.length} collections)`);
    });
    print('\nRun:  node ROLLBACK.js db <backup-folder-name>');
    print('e.g.: node ROLLBACK.js db 2026-06-02T01-00-03');
    return;
  }

  const backupPath = path.join(BACKUP_DIR, backupName);
  if (!fs.existsSync(backupPath)) {
    print(`ERROR: Backup not found: ${backupPath}`);
    return;
  }

  if (!MONGODB_URI) { print('ERROR: MONGODB_URI not set in .env'); return; }

  const mongoose = require(path.join(API_DIR, 'node_modules', 'mongoose'));
  print(`\nRestoring DB from: ${backupName}`);
  print('⚠  This will OVERWRITE existing data in the database.');
  print('   Collections to restore: ' + fs.readdirSync(backupPath).map(f => f.replace('.json.gz', '')).join(', '));
  print('\nConnecting...');

  await mongoose.connect(MONGODB_URI);
  const db = mongoose.connection.db;

  const files = fs.readdirSync(backupPath).filter(f => f.endsWith('.json.gz'));
  for (const file of files) {
    const colName = file.replace('.json.gz', '');
    const gzipped = fs.readFileSync(path.join(backupPath, file));
    const docs    = JSON.parse(zlib.gunzipSync(gzipped).toString());
    if (!docs.length) { print(`  ${colName}: empty — skipped`); continue; }
    const col = db.collection(colName);
    await col.deleteMany({});
    await col.insertMany(docs);
    print(`  ${colName}: restored ${docs.length} docs`);
  }

  await mongoose.disconnect();
  print('\nRestarting API...');
  run('pm2 reload tekeche-api', API_DIR);

  print(`\n✓ DB restored from ${backupName}`);
  hr();
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
const [,, cmd, arg] = process.argv;

switch (cmd) {
  case 'status':                       status();               break;
  case 'api':    rollbackApi(arg);                             break;
  case 'ota':    rollbackOta(arg);                             break;
  case 'db':     restoreDb(arg).catch(console.error);         break;
  default:
    print('\nTekeche Rollback Tool');
    print('─────────────────────');
    print('  node ROLLBACK.js status                — current state');
    print('  node ROLLBACK.js api [tag|commit]      — roll back API');
    print('  node ROLLBACK.js ota [group-id]        — roll back mobile OTA');
    print('  node ROLLBACK.js db  [backup-name]     — restore database');
    print('\nExamples:');
    print('  node ROLLBACK.js api session-2026-06-01');
    print('  node ROLLBACK.js ota b5efd3d8-3eb9-4018-8198-2b4b6d954655');
    print('  node ROLLBACK.js db  2026-06-02T01-00-03');
    print('');
}
