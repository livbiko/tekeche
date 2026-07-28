// Phase 3 of the 20-day bot QA fleet: runtime for ONE synthetic passenger
// identity. Requests rides at randomized realistic intervals, picking
// vehicleType per the fleet's fixed request-mix (5% moto, 50% standard,
// 10% comfort, 5% xl, 30% woyo), waits for the trip to resolve before
// requesting again (mirrors how a real passenger can only have one active
// ride), and never crashes the process on a single failed request.
//
// Usage: node passenger-bot.js <identityIndex>

const { mintToken, apiClient, randomZone, jitterPoint, loadManifest, log } = require('./lib');

const index = parseInt(process.argv[2], 10);
if (!index) { console.error('Usage: node passenger-bot.js <identityIndex>'); process.exit(1); }

const manifest = loadManifest();
const identity = manifest.find(m => m.index === index);
if (!identity) { console.error(`No identity with index ${index} in manifest.json`); process.exit(1); }

const TAG = `passenger#${identity.index}:${identity.name}`;

// Fixed request-mix, independent of the current time window's driver
// composition — matches the role-play spec exactly.
const VEHICLE_WEIGHTS = [
  { type: 'moto',     pct: 5 },
  { type: 'standard', pct: 50 },
  { type: 'comfort',  pct: 10 },
  { type: 'xl',       pct: 5 },
  { type: 'woyo',     pct: 30 },
];

function pickVehicleType() {
  const r = Math.random() * 100;
  let acc = 0;
  for (const w of VEHICLE_WEIGHTS) {
    acc += w.pct;
    if (r <= acc) return w.type;
  }
  return 'standard';
}

function client() { return apiClient(mintToken(identity.userId, 'passenger')); }

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// Realistic "deciding to order a ride" gap between trips for one passenger.
function nextRequestDelayMs() {
  return (5 + Math.random() * 15) * 60 * 1000; // 5–20 minutes
}

function pickupDropoff() {
  let a = randomZone(), b = randomZone();
  while (b.name === a.name) b = randomZone();
  const pickup = jitterPoint(a.lat, a.lng, 1.2);
  const dropoff = jitterPoint(b.lat, b.lng, 1.2);
  return {
    pickupAddress: `${a.name}, Abidjan`,
    pickupLat: pickup.lat, pickupLng: pickup.lng,
    dropoffAddress: `${b.name}, Abidjan`,
    dropoffLat: dropoff.lat, dropoffLng: dropoff.lng,
  };
}

async function waitForTripToResolve() {
  for (;;) {
    let active;
    try {
      const res = await client().get('/rides/active');
      active = res.data.trip;
    } catch (err) {
      // 404/"no active trip" style responses land here depending on the
      // controller — treat any error as "nothing active" and move on.
      active = null;
    }
    if (!active) return;
    log(TAG, `waiting on active trip=${active._id} status=${active.status}`);
    await sleep(15000);
  }
}

async function requestOnce() {
  const vehicleType = pickVehicleType();
  const route = pickupDropoff();

  try {
    if (vehicleType === 'woyo') {
      const res = await client().post('/rides/woyo', {
        pickupAddress: route.pickupAddress, pickupLat: route.pickupLat, pickupLng: route.pickupLng,
        dropoffAddress: route.dropoffAddress, dropoffLat: route.dropoffLat, dropoffLng: route.dropoffLng,
        paymentMethod: 'cash',
      });
      log(TAG, `requested woyo ${route.pickupAddress} -> ${route.dropoffAddress}: trip=${res.data.trip?._id} joined=${!!res.data.joined}`);
    } else {
      const res = await client().post('/rides/request', {
        pickupAddress: route.pickupAddress, pickupLat: route.pickupLat, pickupLng: route.pickupLng,
        dropoffAddress: route.dropoffAddress, dropoffLat: route.dropoffLat, dropoffLng: route.dropoffLng,
        vehicleType, paymentMethod: 'cash',
      });
      log(TAG, `requested ${vehicleType} ${route.pickupAddress} -> ${route.dropoffAddress}: trip=${res.data.trip?._id}`);
    }
  } catch (err) {
    const msg = err.response?.data?.message || err.message;
    log(TAG, `request failed (${vehicleType}): ${msg}`);
  }
}

async function mainLoop() {
  log(TAG, 'passenger bot started');
  for (;;) {
    await waitForTripToResolve();
    const delay = nextRequestDelayMs();
    log(TAG, `next request in ${Math.round(delay / 60000)}min`);
    await sleep(delay);
    await requestOnce();
  }
}

mainLoop().catch(e => { log(TAG, `fatal: ${e.message}`); process.exit(1); });

process.on('SIGINT', () => { log(TAG, 'shutting down'); process.exit(0); });
process.on('SIGTERM', () => { log(TAG, 'shutting down'); process.exit(0); });
