const fs = require('fs');
const crypto = require('crypto');
const https = require('https');
const nodemailer = require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/nodemailer');

const SA = JSON.parse(fs.readFileSync('C:/inetpub/wwwroot/tekeche/tekeche-mobile/google-service-account.json'));

const NEW_TESTER = '2tbpdsarl@gmail.com';

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
    exp: now + 3600,
    iat: now,
  })));
  const signing = `${header}.${payload}`;
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(signing);
  return `${signing}.${base64url(sign.sign(SA.private_key))}`;
}

function httpsRequest(method, url, headers, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const bodyBuf = body
      ? (typeof body === 'string' ? Buffer.from(body) : Buffer.from(JSON.stringify(body)))
      : null;
    const opts = {
      method,
      hostname: u.hostname,
      path: u.pathname + u.search,
      headers: { ...headers },
    };
    if (bodyBuf) {
      opts.headers['Content-Length'] = bodyBuf.length;
      if (!opts.headers['Content-Type']) opts.headers['Content-Type'] = 'application/json';
    }
    const req = https.request(opts, res => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => {
        const text = Buffer.concat(chunks).toString();
        const data = text ? JSON.parse(text) : {};
        if (res.statusCode >= 400) {
          reject(Object.assign(new Error(`HTTP ${res.statusCode}`), { response: { status: res.statusCode, data } }));
        } else {
          resolve(data);
        }
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
  const data = await httpsRequest('POST', 'https://oauth2.googleapis.com/token',
    { 'Content-Type': 'application/x-www-form-urlencoded' }, body);
  return data.access_token;
}

async function addTester(token, pkg, name) {
  const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}`;
  const auth = { Authorization: `Bearer ${token}` };

  const edit = await httpsRequest('POST', `${base}/edits`, auth, {});
  const editId = edit.id;
  console.log(`[${name}] Edit created: ${editId}`);

  try {
    let current = { googleAccounts: [] };
    try {
      current = await httpsRequest('GET', `${base}/edits/${editId}/testers/internal`, auth, null);
      console.log(`[${name}] Current testers: ${(current.googleAccounts || []).join(', ') || '(none)'}`);
    } catch (e) {
      console.log(`[${name}] No existing testers list`);
    }

    if ((current.googleAccounts || []).includes(NEW_TESTER)) {
      console.log(`[${name}] ${NEW_TESTER} is already a tester — skipping`);
      await httpsRequest('DELETE', `${base}/edits/${editId}`, auth, null).catch(() => {});
      return;
    }

    const list = Array.from(new Set([...(current.googleAccounts || []), NEW_TESTER]));
    const updated = await httpsRequest('PUT', `${base}/edits/${editId}/testers/internal`, auth, { googleAccounts: list });
    console.log(`[${name}] Testers updated: ${(updated.googleAccounts || []).join(', ')}`);

    const committed = await httpsRequest('POST', `${base}/edits/${editId}:commit`, auth, {});
    console.log(`[${name}] Edit committed: ${committed.id}`);
    console.log(`[${name}] SUCCESS: ${NEW_TESTER} added as internal tester`);
  } catch (err) {
    await httpsRequest('DELETE', `${base}/edits/${editId}`, auth, null).catch(() => {});
    throw err;
  }
}

async function sendInviteEmail() {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: 'assalehervekouame@gmail.com', pass: 'fbpx rpav tibf rjao' },
  });

  const html = `
<div style="font-family:-apple-system,sans-serif;max-width:600px;margin:0 auto;background:#1A1A2E;color:#F9FAFB;padding:32px;border-radius:16px">
  <h2 style="color:#E8701A;margin-bottom:8px">Bienvenue chez Tekeche &#x1F697;</h2>
  <p style="color:#9CA3AF;margin-bottom:24px">Bonjour,<br><br>
  Vous &ecirc;tes invit&eacute;(e) &agrave; tester l&apos;application <strong style="color:#F9FAFB">Tekeche</strong> en avant-premi&egrave;re.<br>
  Cliquez sur les liens ci-dessous pour rejoindre le programme de test interne sur Google Play.</p>

  <table style="width:100%;border-collapse:collapse">
    <tr><td style="padding:12px 0">
      <a href="https://play.google.com/apps/internaltest/4701081230252324054"
         style="display:block;background:#E8701A;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Rejoindre le test &mdash; Tekeche (Passager)
      </a>
    </td></tr>
    <tr><td style="padding:12px 0">
      <a href="https://play.google.com/apps/internaltest/4701709194279239878"
         style="display:block;background:#374151;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Rejoindre le test &mdash; Tekeche Drive (Chauffeur)
      </a>
    </td></tr>
  </table>

  <p style="color:#6B7280;font-size:13px;margin-top:24px">
    Apr&egrave;s avoir accept&eacute; l&apos;invitation, vous pouvez t&eacute;l&eacute;charger l&apos;application directement depuis Google Play.<br><br>
    Merci pour votre participation !<br>
    <strong style="color:#E8701A">L&apos;&eacute;quipe Tekeche</strong>
  </p>
</div>`;

  const info = await transporter.sendMail({
    from: '"Tekeche" <assalehervekouame@gmail.com>',
    to: NEW_TESTER,
    subject: 'Invitation test interne Tekeche — Google Play',
    html,
  });
  console.log(`\nEmail sent to ${NEW_TESTER} — Message ID: ${info.messageId}`);
}

async function main() {
  console.log(`Adding ${NEW_TESTER} as internal tester on Google Play...\n`);
  const token = await getAccessToken();

  for (const app of APPS) {
    console.log(`\n=== ${app.name} (${app.pkg}) ===`);
    try {
      await addTester(token, app.pkg, app.name);
    } catch (err) {
      const detail = err.response?.data ? JSON.stringify(err.response.data, null, 2) : err.message;
      console.error(`[${app.name}] FAILED:`, detail);
    }
  }

  console.log('\nSending invite email...');
  await sendInviteEmail();
}

main().catch(console.error);
