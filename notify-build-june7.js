// Polls EAS build status for both apps (passenger + driver).
// When both builds finish + 3-min delay for submission processing → sends one email to all testers.
// Run via: node notify-build-june7.js
// Or as pm2: pm2 start notify-build-june7.js --name notify-build-june7

require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/dotenv').config({ path: 'C:/inetpub/wwwroot/tekeche/tekeche-api/.env' });
const nodemailer = require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/nodemailer');
const { execSync } = require('child_process');

const BUILD_IDS = {
  passenger: '14880eed-ad21-4c04-a56c-3c7f030c2407',
  driver:    '169a5003-071e-4922-918b-f20d68d7258b',
};

const TESTERS = [
  'zagocky@gmail.com',
  'welemathias0@gmail.com',
  'tamayazagence@gmail.com',
  'pralph2007@gmail.com',
  'mihiakouameepsemourad@gmail.com',
  'manousaha@gmail.com',
  'macribell@gmail.com',
  'louismartialb@gmail.com',
  'kerneluchiha@gmail.com',
  'honvolionel@gmail.com',
  'hirmineguehi233@gmail.com',
  'florenceclaireb@gmail.com',
  'flobehibro@gmail.com',
  'ettienehoussoumichel3@gmail.com',
  'binanlouismartial@gmail.com',
  'bilerebecca@gmail.com',
  'angelofat78@gmail.com',
  'albankouakou@gmail.com',
  'adjouaangeledjaha@gmail.com',
  'adjouaangeled@gmail.com',
  'abojeany07@gmail.com',
  'tapialatestere@gmail.com',
  'sergeskore5@gmail.com',
  'lindaamani16@gmail.com',
  'kefiacre@gmail.com',
  'hervemalindo@outlook.com',
  '2tbpdsarl@gmail.com',
];

const POLL_INTERVAL_MS = 2 * 60 * 1000; // 2 minutes
const SUBMISSION_GRACE_MS = 3 * 60 * 1000; // 3 min after builds finish before emailing

function getBuildStatuses() {
  const out = execSync(
    'eas build:list --platform android --limit 12 --non-interactive',
    { cwd: 'C:/inetpub/wwwroot/tekeche/tekeche-mobile', encoding: 'utf8', timeout: 30000 }
  );
  const statuses = {};
  const blocks = out.split(/\n(?=ID\s)/);
  for (const block of blocks) {
    const idMatch = block.match(/^ID\s+(\S+)/m);
    const statusMatch = block.match(/^Status\s+(\S+)/m);
    if (idMatch && statusMatch) statuses[idMatch[1]] = statusMatch[1];
  }
  return statuses;
}

const html = `
<div style="font-family:-apple-system,Arial,sans-serif;max-width:560px;margin:0 auto;background:#0A0A0A;color:#FFFFFF;padding:32px;border-radius:16px">
  <h2 style="color:#E8701A;margin:0 0 4px">Tekeche &mdash; Nouvelle version disponible &#x1F4F1;</h2>
  <p style="color:#A0A0A0;font-size:14px;margin:0 0 24px">Mise &agrave; jour disponible sur le Play Store</p>

  <p style="margin:0 0 24px">
    Une nouvelle version de <strong>Tekeche</strong> est disponible sur le Play Store.
    Cette mise &agrave; jour regroupe la livraison de <strong>repas</strong> et de <strong>produits</strong> dans un service unifié, et introduit l&apos;espace <strong>Fournisseur</strong> pour les restaurants et boutiques.
  </p>

  <div style="background:#1A1A1A;border-left:4px solid #E8701A;padding:16px;border-radius:0 8px 8px 0;margin:0 0 20px">
    <p style="margin:0 0 12px;color:#E8701A;font-weight:700">Nouveaut&eacute;s dans cette version</p>
    <ul style="margin:0;color:#D1D5DB;font-size:14px;padding-left:20px;line-height:2">
      <li><strong style="color:#FFFFFF">Service Livraison unifi&eacute;</strong> &mdash; repas et produits regroupés dans une seule section</li>
      <li><strong style="color:#FFFFFF">Espace Fournisseur</strong> &mdash; tableau de bord pour restaurants et boutiques</li>
      <li><strong style="color:#FFFFFF">Gestion des commandes en temps r&eacute;el</strong> &mdash; confirmer, pr&eacute;parer, marquer comme pr&ecirc;t</li>
      <li><strong style="color:#FFFFFF">Menu &amp; Catalogue</strong> &mdash; ajout, modification et disponibilit&eacute; des plats/produits</li>
      <li><strong style="color:#FFFFFF">Mise &agrave; jour automatique</strong> &mdash; l&apos;app signale les nouvelles versions disponibles</li>
    </ul>
  </div>

  <div style="background:#1A1A1A;border-radius:8px;padding:14px;margin:0 0 24px;border:1px solid #333333">
    <p style="margin:0 0 6px;color:#E8701A;font-size:13px;font-weight:700">&#x26A0;&#xFE0F; Action requise</p>
    <p style="margin:0;color:#A0A0A0;font-size:13px;line-height:1.6">
      La mise &agrave; jour <strong style="color:#FFFFFF">ne s&apos;installe pas automatiquement</strong>. Appuyez sur le bouton ci-dessous pour l&apos;ouvrir dans le Play Store et mettre &agrave; jour manuellement.
    </p>
  </div>

  <table style="width:100%;border-collapse:collapse;margin:0 0 24px">
    <tr><td style="padding:6px 0">
      <a href="https://play.google.com/apps/internaltest/4701081230252324054"
         style="display:block;background:#E8701A;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Mettre &agrave; jour Tekeche (Passager)
      </a>
    </td></tr>
    <tr><td style="padding:6px 0">
      <a href="https://play.google.com/apps/internaltest/4701709194279239878"
         style="display:block;background:#374151;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Mettre &agrave; jour Tekeche Drive (Chauffeur)
      </a>
    </td></tr>
  </table>

  <p style="color:#555555;font-size:13px;margin:24px 0 0;border-top:1px solid #222222;padding-top:16px">
    Des bugs ou suggestions ? R&eacute;pondez directement &agrave; cet email.<br>
    <strong style="color:#E8701A">L&apos;&eacute;quipe Tekeche</strong>
  </p>
</div>`;

async function sendNotifications() {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS },
  });

  console.log(`Sending to ${TESTERS.length} testers...\n`);
  let sent = 0, failed = 0;
  for (const to of TESTERS) {
    try {
      await transporter.sendMail({
        from: '"Tekeche" <assalehervekouame@gmail.com>',
        to,
        subject: 'Tekeche — Nouvelle version disponible (Livraison repas & produits)',
        html,
      });
      console.log('  OK  ' + to);
      sent++;
    } catch (e) {
      console.log('  FAIL  ' + to + ' -> ' + e.message);
      failed++;
    }
  }
  console.log(`\nDone. Sent: ${sent}, Failed: ${failed}`);
}

const READY_FLAG    = 'C:/Users/Administrator/notify-ready.json';
const CONFIRM_FLAG  = 'C:/Users/Administrator/notify-confirmed.json';
const fs = require('fs');

// Remove stale flags from a previous run
try { fs.unlinkSync(READY_FLAG);   } catch {}
try { fs.unlinkSync(CONFIRM_FLAG); } catch {}

async function poll() {
  let bothFinished = false;
  let finishedAt = null;
  let waitingConfirm = false;

  while (true) {
    const now = new Date().toISOString();
    try {
      // Once ready, just wait for the confirmation flag
      if (waitingConfirm) {
        if (fs.existsSync(CONFIRM_FLAG)) {
          console.log('Confirmation received — sending notifications...');
          fs.unlinkSync(CONFIRM_FLAG);
          fs.unlinkSync(READY_FLAG);
          await sendNotifications();
          process.exit(0);
        }
        console.log(`[${now}] Awaiting your confirmation...`);
        await new Promise(r => setTimeout(r, 30 * 1000));
        continue;
      }

      const statuses = getBuildStatuses();
      const ps = statuses[BUILD_IDS.passenger] || 'unknown';
      const ds = statuses[BUILD_IDS.driver]    || 'unknown';
      console.log(`[${now}] passenger=${ps}  driver=${ds}`);

      if (ps === 'finished' && ds === 'finished') {
        if (!bothFinished) {
          bothFinished = true;
          finishedAt = Date.now();
          console.log(`Both builds finished. Waiting ${SUBMISSION_GRACE_MS / 1000}s for Play Store submission...`);
        }
        if (Date.now() - finishedAt >= SUBMISSION_GRACE_MS) {
          // Write ready flag and wait for manual confirmation
          fs.writeFileSync(READY_FLAG, JSON.stringify({
            readyAt: now,
            passenger: BUILD_IDS.passenger,
            driver:    BUILD_IDS.driver,
            testers:   TESTERS.length,
          }));
          console.log(`READY_FOR_CONFIRMATION — waiting for your go-ahead.`);
          waitingConfirm = true;
          continue;
        }
      }

      if (ps === 'errored' || ds === 'errored') {
        console.error('One or more builds errored — aborting notification.');
        process.exit(1);
      }
    } catch (e) {
      console.error(`[${now}] Poll error: ${e.message}`);
    }

    await new Promise(r => setTimeout(r, POLL_INTERVAL_MS));
  }
}

poll();
