// Phase 1 of the 20-day bot QA fleet: provisions 35 synthetic User+Driver
// identity pairs on production, isolated from real traffic via isSynthetic
// (see dispatch.service.js / woyo.service.js / admin.controller.js).
//
// Idempotent — re-running skips identities that already exist (matched by
// email) and reports what's already provisioned.
//
// Usage: node provision.js

const fs = require('fs');
const path = require('path');

// mongoose + models are intentionally still loaded from tekeche-api itself
// (not bot-fleet's own package.json) -- they must share the same mongoose
// module instance/connection as the app's own model files, which require
// their own 'mongoose' relative to tekeche-api/node_modules regardless of
// what bot-fleet declares. Override via BOT_FLEET_API_DIR when tekeche-api
// isn't at the default on-prem path (e.g. the OCI standby mirror).
const API_DIR = process.env.BOT_FLEET_API_DIR || 'C:/inetpub/wwwroot/tekeche/tekeche-api';
const MANIFEST_PATH = path.join(__dirname, 'manifest.json');
const mongoose = require(path.join(API_DIR, 'node_modules/mongoose'));

function getEnv(key) {
  const line = fs.readFileSync(path.join(API_DIR, '.env'), 'utf8').split(/\r?\n/).find(l => l.startsWith(key + '='));
  if (!line) throw new Error(`${key} not found in ${API_DIR}/.env`);
  return line.slice(key.length + 1);
}

const User = require(path.join(API_DIR, 'src/models/User'));
const Driver = require(path.join(API_DIR, 'src/models/Driver'));
const Localite = require(path.join(API_DIR, 'src/models/Localite'));

// Real Abidjan communes (approximate commune-centre coordinates) — used both
// for realistic starting GPS positions and, where a matching Localite exists,
// for woyo fare-zone linkage.
const ZONES = [
  { name: 'Plateau',     lat: 5.3200, lng: -4.0200 },
  { name: 'Cocody',      lat: 5.3600, lng: -3.9850 },
  { name: 'Yopougon',    lat: 5.3450, lng: -4.0850 },
  { name: 'Adjamé',      lat: 5.3650, lng: -4.0250 },
  { name: 'Abobo',       lat: 5.4180, lng: -4.0150 },
  { name: 'Koumassi',    lat: 5.2950, lng: -3.9550 },
  { name: 'Marcory',     lat: 5.2950, lng: -3.9800 },
  { name: 'Treichville', lat: 5.2950, lng: -4.0100 },
  { name: 'Port-Bouët',  lat: 5.2550, lng: -3.9350 },
  { name: 'Attécoubé',   lat: 5.3450, lng: -4.0450 },
];

const FIRST_NAMES = ['Kouadio', 'Aya', 'Yao', 'Adjoua', 'Kouassi', 'Akissi', 'Konan', 'Amenan', 'Kouame', 'Affoue',
  'Brou', 'Ahou', 'Kacou', 'Akoua', 'Assi', 'Amoin', 'Yao', 'Adjoa', 'Koffi', 'Aya',
  'Kra', 'Affoue', 'Diaby', 'Fatou', 'Ibrahim', 'Mariam', 'Sekou', 'Aminata', 'Traore', 'Fanta',
  'Coulibaly', 'Awa', 'Ouattara', 'Salimata', 'Bakary'];
const LAST_NAMES = ['Kouassi', 'Yao', 'Kone', 'Diabate', 'Traore', 'Ouattara', 'Bamba', 'Coulibaly', 'Toure', 'Diallo',
  'Kouame', 'Aka', 'N\'Guessan', 'Amani', 'Gnabo', 'Assale', 'Brou', 'Kacou', 'Adou', 'Yapi',
  'Kra', 'Djedje', 'Konan', 'Bile', 'Angoua', 'Zadi', 'Kablan', 'Sery', 'Loba', 'Ake',
  'Sanogo', 'Kamagate', 'Doumbia', 'Sylla', 'Fofana'];

// 35-slot vehicle/role plan: covers the max simultaneous need across all 5
// role-play time windows (see the 20-day fleet scope discussion).
const PLAN = [
  ...Array(5).fill({ vehicleType: 'moto',     woyo: false }),
  ...Array(13).fill({ vehicleType: 'standard', woyo: false }),
  ...Array(5).fill({ vehicleType: 'comfort',  woyo: false }),
  ...Array(4).fill({ vehicleType: 'xl',       woyo: false }),
  ...Array(8).fill({ vehicleType: 'standard', woyo: true  }),
];

async function run() {
  await mongoose.connect(getEnv('MONGODB_URI'));
  console.log('Connected to MongoDB.');

  const abidjan = await Localite.findOne({ name: 'Abidjan', parentId: null }).lean();
  const localites = abidjan ? await Localite.find({ parentId: abidjan._id }).lean() : [];
  const localiteByName = Object.fromEntries(localites.map(l => [l.name, l]));

  const existing = await User.find({ isSynthetic: true, email: /^tekeche\.bot\d+@qa-fleet\.test$/ }).select('email').lean();
  const existingIndices = new Set(existing.map(u => parseInt(u.email.match(/bot(\d+)@/)[1], 10)));
  if (existingIndices.size > 0) {
    console.log(`${existingIndices.size} bot identities already provisioned — skipping those, filling the rest.`);
  }

  const manifest = fs.existsSync(MANIFEST_PATH) ? JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8')) : [];

  for (let i = 1; i <= 35; i++) {
    if (existingIndices.has(i)) continue;

    const spec = PLAN[i - 1];
    const zone = ZONES[(i - 1) % ZONES.length];
    const firstName = FIRST_NAMES[(i * 7) % FIRST_NAMES.length];
    const lastName = LAST_NAMES[(i * 13) % LAST_NAMES.length];
    const name = `${firstName} ${lastName}`;
    const phone = `+225019${String(i).padStart(7, '0')}`;
    const email = `tekeche.bot${i}@qa-fleet.test`;
    const jitter = () => (Math.random() - 0.5) * 0.01; // ~500m spread within the zone

    const user = await User.create({
      phone, name, email,
      isActive: true,
      isSynthetic: true,
      rating: 5.0,
    });

    const driverDoc = {
      phone, email, name,
      vehicleType: spec.vehicleType,
      vehiclePlate: `QA ${String(i).padStart(2, '0')} CI`,
      vehicleModel: spec.vehicleType === 'moto' ? 'Yamaha' : spec.vehicleType === 'xl' ? 'Toyota Hiace' : 'Toyota Corolla',
      kycStatus: 'approved',
      isOnline: false,
      isAvailable: true,
      isActive: true,
      isSynthetic: true,
      woyo: spec.woyo,
      woyoTermsAccepted: spec.woyo,
      location: { type: 'Point', coordinates: [zone.lng + jitter(), zone.lat + jitter()] },
      rating: 5.0,
    };
    if (spec.woyo && localiteByName[zone.name]) {
      driverDoc.woyoLocalite = localiteByName[zone.name]._id;
    }

    const driver = await Driver.create(driverDoc);

    manifest.push({
      index: i,
      name,
      phone,
      email,
      userId: String(user._id),
      driverId: String(driver._id),
      vehicleType: spec.vehicleType,
      woyo: spec.woyo,
      zone: zone.name,
    });

    console.log(`[${i}/35] ${name} — ${spec.woyo ? 'woyo' : spec.vehicleType} driver, zone=${zone.name}`);
  }

  manifest.sort((a, b) => a.index - b.index);
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2));
  console.log(`\nManifest written to ${MANIFEST_PATH} (${manifest.length} identities).`);

  const counts = manifest.reduce((acc, m) => {
    const key = m.woyo ? 'woyo' : m.vehicleType;
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});
  console.log('Fleet composition:', counts);
}

run()
  .then(() => process.exit(0))
  .catch(e => { console.error(e); process.exit(1); })
  .finally(() => mongoose.disconnect());
