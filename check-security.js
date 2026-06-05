const fs = require('fs');

const LOG_FILE = 'C:/inetpub/wwwroot/tekeche/tekeche-api/logs/security.log';

if (!fs.existsSync(LOG_FILE)) { console.log('No security events yet.'); process.exit(0); }

const lines = fs.readFileSync(LOG_FILE, 'utf8').trim().split('\n').filter(Boolean);
if (!lines.length) { console.log('No security events yet.'); process.exit(0); }

const events = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);

// Filter by last N hours (default 24)
const hours = parseInt(process.argv[2]) || 24;
const since = new Date(Date.now() - hours * 3600000);
const recent = events.filter(e => new Date(e.ts) > since);

console.log(`\n── SECURITY LOG — last ${hours}h (${recent.length} events) ──────────────────\n`);

if (!recent.length) { console.log('No events in this window.\n'); process.exit(0); }

// Summary by type
const byType = {};
recent.forEach(e => { byType[e.type] = (byType[e.type] || 0) + 1; });
console.log('SUMMARY:');
Object.entries(byType).sort((a,b) => b[1]-a[1]).forEach(([t,n]) => {
  const icon = {
    suspicious_ua:        '🤖',
    missing_ua:           '❓',
    high_request_volume:  '🌊',
    credential_stuffing:  '🔑',
    path_scanning:        '🔍',
    high_failure_rate:    '🚨',
    auth_failure:         '🔒',
  }[t] ?? '⚠️';
  console.log(`  ${icon} ${t.padEnd(25)} ${n}x`);
});

// Top offending IPs
const ipCount = {};
recent.forEach(e => { if (e.ip) ipCount[e.ip] = (ipCount[e.ip] || 0) + 1; });
const topIPs = Object.entries(ipCount).sort((a,b) => b[1]-a[1]).slice(0, 10);
if (topIPs.length) {
  console.log('\nTOP IPs:');
  topIPs.forEach(([ip, n]) => console.log(`  ${ip.padEnd(20)} ${n} events`));
}

// Recent high-severity events
const highSeverity = ['credential_stuffing','path_scanning','high_request_volume','high_failure_rate'];
const severe = recent.filter(e => highSeverity.includes(e.type));
if (severe.length) {
  console.log('\nHIGH-SEVERITY EVENTS:');
  severe.slice(-10).forEach(e => {
    console.log(`  [${e.ts}] ${e.type} ip=${e.ip}`);
    if (e.emails)      console.log(`    emails: ${e.emails}`);
    if (e.uniquePaths) console.log(`    paths scanned: ${e.uniquePaths}`);
    if (e.reqs)        console.log(`    requests: ${e.reqs}`);
  });
}

// Recent auth failures
const authFails = recent.filter(e => e.type === 'auth_failure');
if (authFails.length) {
  console.log(`\nAUTH FAILURES (${authFails.length} total, showing last 5):`);
  authFails.slice(-5).forEach(e => {
    console.log(`  [${e.ts}] ip=${e.ip} path=${e.path} email=${e.email||'?'} status=${e.status}`);
  });
}

console.log('\n────────────────────────────────────────────────────────\n');
console.log('Usage: node check-security.js [hours]  — default 24h\n');
