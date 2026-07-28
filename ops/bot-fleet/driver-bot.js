// Phase 2 of the 20-day bot QA fleet: runtime for ONE synthetic driver
// identity. Connects via a real Socket.io session (exactly like the real
// app), maintains GPS, accepts dispatched trips, and progresses them through
// the real status lifecycle at realistic driving speeds. After 15 idle
// minutes with no trip, relocates toward a different populated zone.
//
// This process only decides HOW a driver behaves once it's online — WHEN
// each of the 35 identities is online as a driver vs. acting as a passenger
// is Phase 4's job (the window scheduler starts/stops these processes).
//
// Usage: node driver-bot.js <identityIndex>

const { mintToken, apiClient, connectSocket, haversineKm, randomZone, jitterPoint, loadManifest, log } = require('./lib');

const IDLE_RELOCATE_MS = 15 * 60 * 1000; // 15 minutes, per the role-play spec
const GPS_INTERVAL_MS  = 8000;
const SPEED_KMH = { moto: 30, standard: 25, comfort: 25, xl: 22, woyo: 25 };

const index = parseInt(process.argv[2], 10);
if (!index) { console.error('Usage: node driver-bot.js <identityIndex>'); process.exit(1); }

const manifest = loadManifest();
const identity = manifest.find(m => m.index === index);
if (!identity) { console.error(`No identity with index ${index} in manifest.json`); process.exit(1); }

const TAG = `driver#${identity.index}:${identity.name}`;
const speedKmh = identity.woyo ? SPEED_KMH.woyo : SPEED_KMH[identity.vehicleType];

let pos = null;            // { lat, lng } — current simulated position
let idleSince = Date.now();
let activeTrip = null;     // { tripId, phase, dest: {lat,lng} }
let gpsTimer = null;

const client = apiClient(mintToken(identity.driverId, 'driver'));
// Refresh the bearer token used for REST calls before each request cycle —
// cheap local signing, avoids the 15-minute access-token expiry ever biting
// a driver that's been idle a while.
function freshClient() { return apiClient(mintToken(identity.driverId, 'driver')); }

function startZonePosition() {
  const zone = manifest.find(() => true) && require('./lib').ZONES.find(z => z.name === identity.zone);
  const base = zone || randomZone();
  pos = jitterPoint(base.lat, base.lng, 0.5);
}
startZonePosition();

async function sendLocation(lat, lng) {
  pos = { lat, lng };
  try { socket.emit('driver_location', { lat, lng }); } catch {}
}

async function travelTo(destLat, destLng, phaseLabel) {
  const distKm = haversineKm(pos.lat, pos.lng, destLat, destLng);
  const travelMs = Math.min(Math.max((distKm / speedKmh) * 3600 * 1000, 20000), 25 * 60 * 1000);
  const steps = Math.max(3, Math.round(travelMs / GPS_INTERVAL_MS));
  log(TAG, `${phaseLabel}: travelling ${distKm.toFixed(1)}km, ~${Math.round(travelMs / 1000)}s`);

  const startLat = pos.lat, startLng = pos.lng;
  for (let i = 1; i <= steps; i++) {
    await sleep(travelMs / steps);
    const t = i / steps;
    await sendLocation(startLat + (destLat - startLat) * t, startLng + (destLng - startLng) * t);
  }
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function handleTripRequest(payload) {
  if (activeTrip) return; // already busy — shouldn't happen (isAvailable:false), but be safe
  log(TAG, `new_ride_request trip=${payload.tripId} fare=${payload.estimatedFare} dist=${payload.distanceKm}km`);

  // Realistic "driver looks at phone and taps accept" delay.
  await sleep(1000 + Math.random() * 4000);

  try {
    await freshClient().post(`/drivers/trips/${payload.tripId}/accept`);
  } catch (err) {
    log(TAG, `accept failed for trip=${payload.tripId}: ${err.response?.data?.message || err.message}`);
    return;
  }

  activeTrip = { tripId: payload.tripId, pickup: payload.pickup, dropoffAddress: payload.dropoff?.address };
  log(TAG, `accepted trip=${payload.tripId}`);

  try {
    // → pickup
    await travelTo(payload.pickup.lat, payload.pickup.lng, 'en route to passenger');
    await freshClient().put(`/drivers/trips/${payload.tripId}/status`, { status: 'driver_arriving' });
    await sleep(2000);

    await freshClient().put(`/drivers/trips/${payload.tripId}/status`, { status: 'in_progress' });
    log(TAG, `trip=${payload.tripId} passenger onboard`);

    // → dropoff. We aren't told dropoff coordinates in the dispatch payload
    // (only the address), so head toward a plausible nearby point — good
    // enough for realistic movement/GPS-update traffic without needing a
    // geocoder in the loop.
    const destZone = randomZone();
    const dest = jitterPoint(destZone.lat, destZone.lng, 1.5);
    await travelTo(dest.lat, dest.lng, 'driving passenger to destination');

    await freshClient().put(`/drivers/trips/${payload.tripId}/status`, { status: 'completed' });
    log(TAG, `completed trip=${payload.tripId}`);
  } catch (err) {
    log(TAG, `trip=${payload.tripId} lifecycle error: ${err.response?.data?.message || err.message}`);
  } finally {
    activeTrip = null;
    idleSince = Date.now();
  }
}

// Recovers a trip left stranded by an earlier crash/restart of this same
// identity's process — in-memory activeTrip state doesn't survive a process
// restart, but the Trip document does, and dispatch already marked this
// driver unavailable/assigned to it. Without this, an orphaned trip sits at
// whatever status it was in forever (nothing else will ever progress it).
async function recoverActiveTrip() {
  let trip;
  try {
    const res = await freshClient().get('/drivers/active-trip');
    trip = res.data.trip;
  } catch (err) {
    log(TAG, `active-trip check failed: ${err.response?.data?.message || err.message}`);
    return;
  }
  if (!trip) return;

  log(TAG, `recovering orphaned trip=${trip._id} (was status=${trip.status})`);
  activeTrip = { tripId: trip._id };

  try {
    if (trip.status === 'accepted') {
      await travelTo(trip.pickup.coordinates.lat, trip.pickup.coordinates.lng, 'recovering: en route to passenger');
      await freshClient().put(`/drivers/trips/${trip._id}/status`, { status: 'driver_arriving' });
      await sleep(2000);
      await freshClient().put(`/drivers/trips/${trip._id}/status`, { status: 'in_progress' });
    } else if (trip.status === 'driver_arriving') {
      await sleep(2000);
      await freshClient().put(`/drivers/trips/${trip._id}/status`, { status: 'in_progress' });
    }
    // Recovered trips use the trip document's own real dropoff coordinates
    // (unlike the live dispatch payload, which only carries a dropoff
    // address) — this path actually has better data than the happy path.
    if (trip.dropoff?.coordinates?.lat) {
      await travelTo(trip.dropoff.coordinates.lat, trip.dropoff.coordinates.lng, 'recovering: driving to destination');
    }
    await freshClient().put(`/drivers/trips/${trip._id}/status`, { status: 'completed' });
    log(TAG, `recovered trip=${trip._id} completed`);
  } catch (err) {
    log(TAG, `recovery error for trip=${trip._id}: ${err.response?.data?.message || err.message}`);
  } finally {
    activeTrip = null;
    idleSince = Date.now();
  }
}

async function maybeRelocate() {
  if (activeTrip) return;
  if (Date.now() - idleSince < IDLE_RELOCATE_MS) return;
  const zone = randomZone();
  const dest = jitterPoint(zone.lat, zone.lng, 1.0);
  log(TAG, `idle ${Math.round((Date.now() - idleSince) / 60000)}min — relocating toward ${zone.name}`);
  await travelTo(dest.lat, dest.lng, `relocating to ${zone.name}`);
  idleSince = Date.now();
}

// ── Socket lifecycle ──────────────────────────────────────────────────────
const socket = connectSocket(mintToken(identity.driverId, 'driver'));
// Dynamic auth: socket.io-client calls this fresh on every (re)connect
// attempt, so a token minted at process start never goes stale across
// reconnects over the 20-day run.
socket.auth = (cb) => cb({ token: mintToken(identity.driverId, 'driver') });

socket.on('connect', () => {
  log(TAG, `online (socket ${socket.id}) at zone=${identity.zone} vehicleType=${identity.vehicleType} woyo=${identity.woyo}`);
  sendLocation(pos.lat, pos.lng);
});

socket.on('disconnect', (reason) => log(TAG, `disconnected: ${reason}`));
socket.on('connect_error', (err) => log(TAG, `connect_error: ${err.message}`));

socket.on('new_ride_request', (payload) => { handleTripRequest(payload).catch(e => log(TAG, `handleTripRequest error: ${e.message}`)); });
socket.on('woyo_new_passenger', (payload) => log(TAG, `woyo_new_passenger trip=${payload.tripId} totalPassengers=${payload.totalPassengers}`));
socket.on('trip_cancelled_by_passenger', () => { log(TAG, 'trip cancelled by passenger'); activeTrip = null; idleSince = Date.now(); });

// Recover any trip orphaned by a previous crash of this identity before
// doing anything else, then start the normal GPS/idle-relocation loop.
recoverActiveTrip().finally(() => {
  gpsTimer = setInterval(() => {
    if (!activeTrip) sendLocation(pos.lat, pos.lng);
    maybeRelocate().catch(e => log(TAG, `relocate error: ${e.message}`));
  }, GPS_INTERVAL_MS);
});

process.on('SIGINT', () => { log(TAG, 'shutting down'); socket.disconnect(); process.exit(0); });
process.on('SIGTERM', () => { log(TAG, 'shutting down'); socket.disconnect(); process.exit(0); });
