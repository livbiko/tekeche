// Shared helpers for the bot QA fleet (Phases 2+). Every bot process hits the
// real public API (https://api.tekeche.com) exactly like a real app would —
// isSynthetic isolation is what keeps this safe on production, not a
// separate internal-only endpoint.
const fs = require('fs');
const path = require('path');

const API_DIR   = 'C:/inetpub/wwwroot/tekeche/tekeche-api';
const MOBILE_DIR = 'C:/inetpub/wwwroot/tekeche/tekeche-mobile';

const jwt   = require(path.join(API_DIR, 'node_modules/jsonwebtoken'));
const axios = require(path.join(API_DIR, 'node_modules/axios'));
const { io } = require(path.join(MOBILE_DIR, 'node_modules/socket.io-client'));

function getEnv(key) {
  const line = fs.readFileSync(path.join(API_DIR, '.env'), 'utf8').split(/\r?\n/).find(l => l.startsWith(key + '='));
  if (!line) throw new Error(`${key} not found in tekeche-api/.env`);
  return line.slice(key.length + 1);
}

const JWT_SECRET = getEnv('JWT_SECRET');
const API_BASE   = 'https://api.tekeche.com/api';
const SOCKET_URL = 'https://api.tekeche.com';

// Mirrors signTokens() in auth.controller.js exactly (id, role, jti, type,
// same expiresIn) so bot tokens are indistinguishable in shape from real ones.
function mintToken(id, role) {
  const jti = require('crypto').randomBytes(16).toString('hex');
  return jwt.sign({ id, role, jti, type: 'access' }, JWT_SECRET, { expiresIn: '15m' });
}

function apiClient(token) {
  return axios.create({
    baseURL: API_BASE,
    headers: { Authorization: `Bearer ${token}` },
    timeout: 15000,
  });
}

function connectSocket(token) {
  return io(SOCKET_URL, {
    auth: { token },
    transports: ['websocket', 'polling'],
    reconnection: true,
    reconnectionDelay: 2000,
    reconnectionDelayMax: 15000,
  });
}

// Real Abidjan communes — kept identical to provision.js's zone list so bot
// movement stays within the same geography their identities were seeded in.
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

function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const toRad = d => d * Math.PI / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function randomZone() {
  return ZONES[Math.floor(Math.random() * ZONES.length)];
}

function jitterPoint(lat, lng, spreadKm = 0.8) {
  const dLat = (Math.random() - 0.5) * (spreadKm / 111);
  const dLng = (Math.random() - 0.5) * (spreadKm / (111 * Math.cos(lat * Math.PI / 180)));
  return { lat: lat + dLat, lng: lng + dLng };
}

function loadManifest() {
  return JSON.parse(fs.readFileSync(path.join(__dirname, 'manifest.json'), 'utf8'));
}

function log(tag, msg) {
  console.log(`[${new Date().toISOString()}] [${tag}] ${msg}`);
}

module.exports = {
  API_BASE, SOCKET_URL, ZONES,
  mintToken, apiClient, connectSocket,
  haversineKm, randomZone, jitterPoint,
  loadManifest, log,
};
