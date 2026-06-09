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
  <h2 style="color:#E8701A;margin:0 0 4px">Tekeche &mdash; Les premi&egrave;res vraies commandes &#x1F389;</h2>
  <p style="color:#A0A0A0;font-size:14px;margin:0 0 24px">Mise &agrave; jour test &mdash; 9 juin 2026</p>

  <p style="margin:0 0 20px;line-height:1.6">
    Bonne nouvelle&nbsp;: les premi&egrave;res commandes r&eacute;elles arrivent&nbsp;!
    Un chauffeur a &eacute;t&eacute; assign&eacute; &agrave; une commande en cours chez <strong>Chez Kouam&eacute;</strong>.
    Les deux parcours &mdash; livraison de repas et VTC &mdash; sont op&eacute;rationnels.
    Continuez &agrave; tester et signalez tout probl&egrave;me en r&eacute;pondant &agrave; cet email.
  </p>

  <div style="background:#1A1A1A;border-left:4px solid #E8701A;padding:16px;border-radius:0 8px 8px 0;margin:0 0 16px">
    <p style="margin:0 0 8px;color:#E8701A;font-weight:700">&#x1F355; Livraison &mdash; quoi tester</p>
    <ul style="margin:0;color:#D1D5DB;font-size:14px;padding-left:20px;line-height:2.2">
      <li>Commander chez <strong style="color:#FFFFFF">Chez Kouam&eacute;</strong> (32 plats disponibles)</li>
      <li>V&eacute;rifier le suivi de commande en temps r&eacute;el</li>
      <li>Tester les diff&eacute;rents modes de paiement&nbsp;: esp&egrave;ces, Orange Money, MTN MoMo, Wave</li>
      <li>Laisser un avis apr&egrave;s livraison</li>
    </ul>
  </div>

  <div style="background:#1A1A1A;border-left:4px solid #E8701A;padding:16px;border-radius:0 8px 8px 0;margin:0 0 24px">
    <p style="margin:0 0 8px;color:#E8701A;font-weight:700">&#x1F697; VTC &mdash; quoi tester</p>
    <ul style="margin:0;color:#D1D5DB;font-size:14px;padding-left:20px;line-height:2.2">
      <li>R&eacute;server une course depuis la section <strong style="color:#FFFFFF">Course</strong></li>
      <li>Tester les diff&eacute;rents types de v&eacute;hicule (moto, standard, confort&hellip;)</li>
      <li><strong style="color:#FFFFFF">Chauffeurs</strong>&nbsp;: connectez-vous sur Tekeche Drive et passez en ligne</li>
      <li>V&eacute;rifier la notification d&apos;arriv&eacute;e du chauffeur</li>
    </ul>
  </div>

  <table style="width:100%;border-collapse:collapse;margin:0 0 24px">
    <tr><td style="padding:6px 0">
      <a href="https://play.google.com/apps/internaltest/4701081230252324054"
         style="display:block;background:#E8701A;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Ouvrir Tekeche &mdash; Passager &#x1F6D5;
      </a>
    </td></tr>
    <tr><td style="padding:6px 0">
      <a href="https://play.google.com/apps/internaltest/4701709194279239878"
         style="display:block;background:#374151;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Ouvrir Tekeche Drive &mdash; Chauffeur &#x1F697;
      </a>
    </td></tr>
  </table>

  <p style="color:#555555;font-size:13px;margin:24px 0 0;border-top:1px solid #222222;padding-top:16px">
    Des bugs ou suggestions&nbsp;? R&eacute;pondez directement &agrave; cet email.<br>
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
        subject: 'Tekeche — Les premières vraies commandes arrivent 🎉',
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
