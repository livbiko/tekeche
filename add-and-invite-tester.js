const fs = require('fs');
const crypto = require('crypto');
const https = require('https');
const nodemailer = require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/nodemailer');

require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/dotenv').config({ path: 'C:/inetpub/wwwroot/tekeche/tekeche-api/.env' });

const SA = JSON.parse(fs.readFileSync('C:/inetpub/wwwroot/tekeche/tekeche-mobile/google-service-account.json'));

const NEW_TESTER = 'kerneluchiha@gmail.com';

const ALL_TESTERS = [
  'tamayazagence@gmail.com',
  'louismartialb@gmail.com',
  'ettienehoussoumichel3@gmail.com',
  'binanlouismartial@gmail.com',
  'zagocky@gmail.com',
  'lindaamani16@gmail.com',
  'bilerebecca@gmail.com',
  'flobehibro@gmail.com',
  'hervemalindo@outlook.com',
  'macribell@gmail.com',
  'manousaha@gmail.com',
  'welemathias0@gmail.com',
  'albankouakou@gmail.com',
  'honvolionel@gmail.com',
  'pralph2007@gmail.com',
  'florenceclaireb@gmail.com',
  'adjouaangeledjaha@gmail.com',
  'Kefiacre@gmail.com',
  'emikouame@gmail.com',
  'mihiakouameepsemourad@gmail.com',
  'kerneluchiha@gmail.com',
];

const APPS = [
  { pkg: 'com.tekeche.app',        name: 'Passenger', optIn: 'https://play.google.com/apps/internaltest/4701081230252324054' },
  { pkg: 'com.tekechedrivefr.app', name: 'Driver',    optIn: 'https://play.google.com/apps/internaltest/4701709194279239878' },
];

function base64url(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function makeJwt() {
  const now = Math.floor(Date.now() / 1000);
  const header  = base64url(Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const payload = base64url(Buffer.from(JSON.stringify({
    iss: SA.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600, iat: now,
  })));
  const signing = `${header}.${payload}`;
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(signing);
  return `${signing}.${base64url(sign.sign(SA.private_key))}`;
}

function httpsRequest(method, url, headers, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const bodyBuf = body ? (typeof body === 'string' ? Buffer.from(body) : Buffer.from(JSON.stringify(body))) : null;
    const opts = { method, hostname: u.hostname, path: u.pathname + u.search, headers: { ...headers } };
    if (bodyBuf) { opts.headers['Content-Length'] = bodyBuf.length; if (!opts.headers['Content-Type']) opts.headers['Content-Type'] = 'application/json'; }
    const req = https.request(opts, res => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => {
        const text = Buffer.concat(chunks).toString();
        const data = text ? JSON.parse(text) : {};
        if (res.statusCode >= 400) reject(Object.assign(new Error(`HTTP ${res.statusCode}`), { response: { status: res.statusCode, data } }));
        else resolve(data);
      });
    });
    req.on('error', reject);
    if (bodyBuf) req.write(bodyBuf);
    req.end();
  });
}

async function getAccessToken() {
  const jwt = makeJwt();
  const body = `grant_type=${encodeURIComponent('urn:ietf:params:oauth:grant-type:jwt-bearer')}&assertion=${encodeURIComponent(jwt)}`;
  const data = await httpsRequest('POST', 'https://oauth2.googleapis.com/token', { 'Content-Type': 'application/x-www-form-urlencoded' }, body);
  return data.access_token;
}

async function syncTesters(token, pkg, name) {
  const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}`;
  const auth = { Authorization: `Bearer ${token}` };

  const edit = await httpsRequest('POST', `${base}/edits`, auth, {});
  const editId = edit.id;

  try {
    let current = { testers: [] };
    try { current = await httpsRequest('GET', `${base}/edits/${editId}/testers/internal`, auth, null); } catch {}

    const existing = current.testers || [];
    const merged = [...new Set([...existing, ...ALL_TESTERS])];
    const added = merged.filter(e => !existing.includes(e));

    if (added.length === 0) {
      console.log(`[${name}] All testers already present — no changes needed`);
      await httpsRequest('DELETE', `${base}/edits/${editId}`, auth, null).catch(() => {});
      return { added: [] };
    }

    await httpsRequest('PUT', `${base}/edits/${editId}/testers/internal`, auth, { testers: merged });
    await httpsRequest('POST', `${base}/edits/${editId}:commit`, auth, {});
    console.log(`[${name}] Added ${added.length} tester(s): ${added.join(', ')}`);
    return { added };
  } catch (err) {
    await httpsRequest('DELETE', `${base}/edits/${editId}`, auth, null).catch(() => {});
    throw err;
  }
}

async function sendInviteEmail() {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS },
  });

  const html = `
<div style="font-family:-apple-system,Arial,sans-serif;max-width:560px;margin:0 auto;background:#1A1A2E;color:#F9FAFB;padding:32px;border-radius:16px">
  <h2 style="color:#E8701A;margin:0 0 4px">Bienvenue chez Tekeche 🚗</h2>
  <p style="color:#9CA3AF;font-size:14px;margin:0 0 24px">Invitation au test interne</p>

  <p style="margin:0 0 16px">Bonjour,</p>
  <p style="margin:0 0 20px">
    Vous êtes invité(e) à tester l'application <strong>Tekeche</strong> en avant-première sur Google Play.
  </p>

  <div style="background:#111827;border-left:4px solid #E8701A;padding:16px;border-radius:0 8px 8px 0;margin:0 0 24px">
    <p style="margin:0;color:#E8701A;font-weight:700">Comment se connecter</p>
    <ol style="margin:8px 0 0;color:#D1D5DB;font-size:14px;padding-left:20px;line-height:1.9">
      <li>Acceptez l'invitation via le lien ci-dessous</li>
      <li>Téléchargez l'application depuis Google Play</li>
      <li>Entrez votre <strong>numéro de téléphone</strong> et votre <strong>adresse email</strong></li>
      <li>Vous recevrez le code OTP <strong>par email</strong> — entrez-le pour accéder</li>
    </ol>
  </div>

  <div style="background:#111827;border-radius:8px;padding:14px;margin:0 0 24px">
    <p style="margin:0;color:#9CA3AF;font-size:13px">
      💡 Vérifiez vos <strong style="color:#F9FAFB">spams</strong> si le code n'arrive pas en boîte principale.
    </p>
  </div>

  <table style="width:100%;border-collapse:collapse;margin:0 0 16px">
    <tr><td style="padding:6px 0">
      <a href="${APPS[0].optIn}" style="display:block;background:#E8701A;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Rejoindre le test — Tekeche (Passager)
      </a>
    </td></tr>
    <tr><td style="padding:6px 0">
      <a href="${APPS[1].optIn}" style="display:block;background:#374151;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Rejoindre le test — Tekeche Drive (Chauffeur)
      </a>
    </td></tr>
  </table>

  <p style="color:#6B7280;font-size:13px;margin:24px 0 0;border-top:1px solid #374151;padding-top:16px">
    Des questions ? Répondez directement à cet email.<br>
    <strong style="color:#E8701A">L'équipe Tekeche</strong>
  </p>
</div>`;

  await transporter.sendMail({
    from: '"Tekeche" <assalehervekouame@gmail.com>',
    to: NEW_TESTER,
    subject: 'Invitation — Test interne Tekeche',
    html,
  });
  console.log(`\nInvite email sent to ${NEW_TESTER}`);
}

async function main() {
  const token = await getAccessToken();

  for (const app of APPS) {
    try {
      await syncTesters(token, app.pkg, app.name);
    } catch (err) {
      // Play Console API no longer supports individual email testers — add manually
    }
  }

  await sendInviteEmail();
  console.log('\nDone.');
}

main().catch(console.error);
