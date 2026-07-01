'use strict';

const axios = require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/axios').default;
const { io }  = require('C:/inetpub/wwwroot/tekeche/tekeche-mobile/node_modules/socket.io-client');
const { MongoClient, ObjectId } = require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/mongodb');

const BASE      = 'http://127.0.0.1:5000';   // production API
const MONGO_URI = 'mongodb://tekeche:6eY7EvTt57HM2dgmPgrsr64u@127.0.0.1:27017/tekeche';
const PASS_EMAIL   = 'assalehervekouame+passager1@gmail.com';
const DRIVER_EMAIL = 'honvolionel@gmail.com';

const pass = (msg) => console.log(`  ✅  ${msg}`);
const fail = (msg) => { console.error(`  ❌  ${msg}`); process.exit(1); };
const step = (n, msg) => console.log(`\n[${n}] ${msg}`);

async function http(method, path, data, token) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  try {
    const res = await axios({ method, url: `${BASE}${path}`, data, headers, timeout: 10000 });
    return res.data;
  } catch (e) {
    const body = e.response?.data;
    throw new Error(`${method.toUpperCase()} ${path} → ${e.response?.status} ${JSON.stringify(body)}`);
  }
}

async function main() {
  console.log('=== Tekeche booking flow test (PRODUCTION port 5000) ===\n');

  step(0, 'Connecting to MongoDB...');
  const client = await MongoClient.connect(MONGO_URI);
  const db = client.db('tekeche');
  pass('MongoDB connected');

  step(1, `Checking driver: ${DRIVER_EMAIL}`);
  const driver = await db.collection('drivers').findOne({ email: DRIVER_EMAIL });
  if (!driver) fail(`Driver ${DRIVER_EMAIL} not found`);
  if (!driver.isOnline)    fail(`Driver is offline — open Tekeche Driver app first`);
  if (!driver.isAvailable) fail(`Driver is not available (mid-dispatch)`);
  if (!driver.socketId)    fail(`Driver has no socket connection — check driver app`);
  pass(`${driver.name} | ${driver.vehicleType} | kyc=${driver.kycStatus} | socket=${driver.socketId.slice(0,8)}...`);

  step(2, `Authenticating passenger via OTP: ${PASS_EMAIL}`);
  await db.collection('otps').deleteMany({ email: PASS_EMAIL, role: 'passenger' });
  await db.collection('otps').insertOne({
    email: PASS_EMAIL, code: '111111', role: 'passenger',
    name: 'Passager Test 1', surname: 'Test',
    attempts: 0, expiresAt: new Date(Date.now() + 5 * 60_000), createdAt: new Date(),
  });
  const pRes = await http('POST', '/api/auth/verify-otp', { email: PASS_EMAIL, code: '111111', role: 'passenger' });
  if (!pRes.token) fail(`No token: ${JSON.stringify(pRes)}`);
  const passengerToken = pRes.token;
  pass(`Passenger: "${pRes.user.name}" id=${pRes.user._id}`);

  step(3, `Authenticating driver via OTP: ${DRIVER_EMAIL}`);
  await db.collection('otps').deleteMany({ email: DRIVER_EMAIL, role: 'driver' });
  await db.collection('otps').insertOne({
    email: DRIVER_EMAIL, code: '222222', role: 'driver',
    attempts: 0, expiresAt: new Date(Date.now() + 5 * 60_000), createdAt: new Date(),
  });
  const dRes = await http('POST', '/api/auth/verify-otp', { email: DRIVER_EMAIL, code: '222222', role: 'driver' });
  if (!dRes.token) fail(`No driver token: ${JSON.stringify(dRes)}`);
  const driverToken = dRes.token;
  pass(`Driver: "${dRes.user.name}" role=${dRes.role}`);

  step(4, 'Connecting driver socket...');
  const dSocket = io(BASE, { auth: { token: driverToken }, transports: ['websocket'], timeout: 8000 });
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('Socket connect timeout (8s)')), 8000);
    dSocket.on('connect', () => { clearTimeout(t); resolve(); });
    dSocket.on('connect_error', (e) => { clearTimeout(t); reject(new Error(`Socket: ${e.message}`)); });
  });
  pass(`Driver socket: ${dSocket.id}`);
  await new Promise(r => setTimeout(r, 600));

  const dbDriver = await db.collection('drivers').findOne({ _id: driver._id });
  if (!dbDriver.isOnline) fail('Driver not marked online after socket connect');
  pass(`isOnline=${dbDriver.isOnline} isAvailable=${dbDriver.isAvailable}`);

  step(5, 'Connecting passenger socket...');
  const pSocket = io(BASE, { auth: { token: passengerToken }, transports: ['websocket'], timeout: 8000 });
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('Passenger socket timeout')), 8000);
    pSocket.on('connect', () => { clearTimeout(t); resolve(); });
    pSocket.on('connect_error', (e) => { clearTimeout(t); reject(new Error(e.message)); });
  });
  pass(`Passenger socket: ${pSocket.id}`);

  const passengerEvents = [];
  ['trip_accepted','trip_status_update','no_driver_found'].forEach(ev => {
    pSocket.on(ev, (d) => { console.log(`    [pax socket] ${ev}: ${JSON.stringify(d)}`); passengerEvents.push(ev); });
  });

  step(6, 'Requesting a standard ride (cash)...');
  const rideReqPromise = new Promise(resolve => dSocket.on('new_ride_request', resolve));

  const rideRes = await http('POST', '/api/rides/request', {
    pickupAddress:  'Plateau, Abidjan',
    pickupLat:  5.3209, pickupLng:  3.9941,
    dropoffAddress: 'Cocody, Abidjan',
    dropoffLat: 5.3599, dropoffLng: 3.9918,
    vehicleType: 'standard',
    paymentMethod: 'cash',
  }, passengerToken);
  if (!rideRes.success) fail(`requestRide: ${rideRes.message} (code=${rideRes.code})`);
  const tripId = rideRes.trip._id;
  pass(`Trip ${tripId} | status=${rideRes.trip.status} | fare=${rideRes.trip.estimatedFare} XOF`);

  step(7, 'Waiting for driver to receive new_ride_request (15s)...');
  const ridePayload = await Promise.race([
    rideReqPromise,
    new Promise((_, rej) => setTimeout(() => rej(new Error('Timeout — driver never got new_ride_request')), 15000)),
  ]);
  pass(`Driver got request — tripId=${ridePayload.tripId} fare=${ridePayload.estimatedFare} timeout=${ridePayload.timeout}s`);

  step(8, 'Driver accepts...');
  const acceptRes = await http('POST', `/api/drivers/trips/${tripId}/accept`, {}, driverToken);
  if (!acceptRes.success) fail(`accept: ${acceptRes.message}`);
  pass(`Accepted — status=${acceptRes.trip?.status}`);
  await new Promise(r => setTimeout(r, 400));

  step(9, 'Driver → driver_arriving...');
  const arr = await http('PUT', `/api/drivers/trips/${tripId}/status`, { status: 'driver_arriving' }, driverToken);
  if (!arr.success) fail(`driver_arriving: ${arr.message}`);
  pass('status=driver_arriving');
  await new Promise(r => setTimeout(r, 400));

  step(10, 'Driver → in_progress...');
  const start = await http('PUT', `/api/drivers/trips/${tripId}/status`, { status: 'in_progress' }, driverToken);
  if (!start.success) fail(`in_progress: ${start.message}`);
  pass('status=in_progress');
  await new Promise(r => setTimeout(r, 400));

  step(11, 'Driver → completed...');
  const done = await http('PUT', `/api/drivers/trips/${tripId}/status`, { status: 'completed' }, driverToken);
  if (!done.success) fail(`completed: ${done.message}`);
  pass('status=completed');

  step(12, 'Verifying DB...');
  await new Promise(r => setTimeout(r, 400));
  const trip   = await db.collection('trips').findOne({ _id: new ObjectId(String(tripId)) });
  const finalD = await db.collection('drivers').findOne({ _id: driver._id });

  if (trip.status !== 'completed') fail(`Trip status=${trip.status}, expected completed`);
  pass(`Trip in DB: status=${trip.status} driver=${trip.driver}`);
  pass(`Driver: isAvailable=${finalD.isAvailable} isOnline=${finalD.isOnline}`);

  if (passengerEvents.length) pass(`Passenger socket events: ${passengerEvents.join(', ')}`);
  else console.log('  ⚠️   No passenger socket events received (check cross-node fan-out)');

  dSocket.disconnect();
  pSocket.disconnect();
  await db.collection('trips').deleteOne({ _id: new ObjectId(String(tripId)) });
  await client.close();

  console.log('\n══════════════════════════════════════════');
  console.log('  ✅  PRODUCTION BOOKING FLOW PASSED');
  console.log('══════════════════════════════════════════\n');
}

main().catch(err => {
  console.error(`\n❌  ${err.message}`);
  process.exit(1);
});
