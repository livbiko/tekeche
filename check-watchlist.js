const fs   = require('fs');
const path = require('path');

const LOG_FILE = 'C:/inetpub/wwwroot/tekeche/tekeche-api/logs/watchlist.log';

if (!fs.existsSync(LOG_FILE)) {
  console.log('No watchlist hits yet.');
  process.exit(0);
}

const lines = fs.readFileSync(LOG_FILE, 'utf8').trim().split('\n').filter(Boolean);
if (!lines.length) { console.log('No watchlist hits yet.'); process.exit(0); }

console.log(`\n── WATCHLIST LOG (${lines.length} hits) ──────────────────────\n`);

const hits = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);

// Group by trigger
const grouped = {};
hits.forEach(h => {
  const key = h.trigger;
  if (!grouped[key]) grouped[key] = [];
  grouped[key].push(h);
});

for (const [trigger, entries] of Object.entries(grouped)) {
  console.log(`\n▶ ${trigger} — ${entries.length} hit(s)`);
  const uniqueIPs = [...new Set(entries.map(e => e.ip).filter(Boolean))];
  console.log(`  IPs seen: ${uniqueIPs.join(', ') || 'unknown'}`);
  entries.slice(-5).forEach(e => {
    console.log(`  [${e.ts}] ${e.method} ${e.path} ip=${e.ip} ua=${e.ua?.slice(0,60) ?? '?'}`);
  });
  if (entries.length > 5) console.log(`  ... and ${entries.length - 5} earlier hits`);
}

console.log('\n────────────────────────────────────────────────────────\n');
