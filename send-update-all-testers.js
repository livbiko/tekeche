require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/dotenv').config({ path: 'C:/inetpub/wwwroot/tekeche/tekeche-api/.env' });
const nodemailer = require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/nodemailer');

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

const html = `
<div style="font-family:-apple-system,Arial,sans-serif;max-width:560px;margin:0 auto;background:#0A0A0A;color:#FFFFFF;padding:32px;border-radius:16px">
  <h2 style="color:#E8701A;margin:0 0 4px">Tekeche &mdash; Commande de repas disponible &#x1F37D;&#xFE0F;</h2>
  <p style="color:#A0A0A0;font-size:14px;margin:0 0 24px">Testez la livraison de repas depuis l&apos;app</p>

  <p style="margin:0 0 24px">
    Le service de <strong>livraison de repas</strong> est maintenant op&eacute;rationnel.
    Vous pouvez passer une commande chez <strong>Chez Kouam&eacute;</strong> directement depuis la section <strong>Livraison</strong> de l&apos;app.
  </p>

  <div style="background:#1A1A1A;border-left:4px solid #E8701A;padding:16px;border-radius:0 8px 8px 0;margin:0 0 20px">
    <p style="margin:0 0 12px;color:#E8701A;font-weight:700">Chez Kouam&eacute; &mdash; Cuisine locale, Cocody Abidjan</p>
    <ul style="margin:0;color:#D1D5DB;font-size:14px;padding-left:20px;line-height:2">
      <li><strong style="color:#FFFFFF">32 plats au menu</strong> &mdash; Garba, Kedjenou, Foutou, Attiék&eacute;&hellip;</li>
      <li><strong style="color:#FFFFFF">Grillades</strong> &mdash; Poulet, Poisson, Pintade, Tilapia</li>
      <li><strong style="color:#FFFFFF">Soupes, Desserts &amp; Boissons</strong> &mdash; Bissap, Gnamakoudji, Beignets&hellip;</li>
      <li><strong style="color:#FFFFFF">Livraison &agrave; partir de 500 FCFA</strong> &mdash; commande minimum 1&nbsp;000 FCFA</li>
    </ul>
  </div>

  <div style="background:#1A1A1A;border-radius:8px;padding:14px;margin:0 0 24px;border:1px solid #333333">
    <p style="margin:0 0 6px;color:#E8701A;font-size:13px;font-weight:700">Comment tester ?</p>
    <ol style="margin:0;color:#A0A0A0;font-size:13px;line-height:2;padding-left:18px">
      <li>Ouvrez Tekeche &rarr; section <strong style="color:#FFFFFF">Livraison</strong></li>
      <li>S&eacute;lectionnez <strong style="color:#FFFFFF">Chez Kouam&eacute;</strong></li>
      <li>Ajoutez des plats et passez commande</li>
      <li>Signalez tout bug en r&eacute;pondant &agrave; cet email</li>
    </ol>
  </div>

  <table style="width:100%;border-collapse:collapse;margin:0 0 24px">
    <tr><td style="padding:6px 0">
      <a href="https://play.google.com/apps/internaltest/4701081230252324054"
         style="display:block;background:#E8701A;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Ouvrir Tekeche (Passager)
      </a>
    </td></tr>
    <tr><td style="padding:6px 0">
      <a href="https://play.google.com/apps/internaltest/4701709194279239878"
         style="display:block;background:#374151;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Ouvrir Tekeche Drive (Chauffeur)
      </a>
    </td></tr>
  </table>

  <p style="color:#555555;font-size:13px;margin:24px 0 0;border-top:1px solid #222222;padding-top:16px">
    Des bugs ou suggestions ? R&eacute;pondez directement &agrave; cet email.<br>
    <strong style="color:#E8701A">L&apos;&eacute;quipe Tekeche</strong>
  </p>
</div>`;

async function send() {
  const t = nodemailer.createTransport({ service: 'gmail', auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS } });
  console.log(`Sending to ${TESTERS.length} testers...\n`);
  let sent = 0, failed = 0;
  for (const to of TESTERS) {
    try {
      await t.sendMail({
        from: '"Tekeche" <assalehervekouame@gmail.com>',
        to,
        subject: 'Tekeche — Commandez vos repas chez Chez Kouamé 🍽️',
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

send();
