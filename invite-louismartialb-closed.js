require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/dotenv').config({ path: 'C:/inetpub/wwwroot/tekeche/tekeche-api/.env' });
const nodemailer = require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS },
});

const html = `
<div style="font-family:-apple-system,Arial,sans-serif;max-width:560px;margin:0 auto;background:#1A1A2E;color:#F9FAFB;padding:32px;border-radius:16px">
  <h2 style="color:#E8701A;margin:0 0 4px">Bienvenue chez Tekeche 🚗</h2>
  <p style="color:#9CA3AF;font-size:14px;margin:0 0 24px">Invitation au test fermé (Alpha)</p>

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
      <a href="https://play.google.com/apps/testing/com.tekeche.app"
         style="display:block;background:#E8701A;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Rejoindre le test — Tekeche (Passager)
      </a>
    </td></tr>
    <tr><td style="padding:6px 0">
      <a href="https://play.google.com/apps/testing/com.tekechedrivefr.app"
         style="display:block;background:#374151;color:#fff;text-decoration:none;padding:14px 24px;border-radius:12px;font-weight:700;text-align:center">
        Rejoindre le test — Tekeche Drive (Chauffeur)
      </a>
    </td></tr>
  </table>

  <p style="color:#6B7280;font-size:13px;margin:24px 0 0;border-top:1px solid #374151;padding-top:16px">
    Des questions ? Répondez directement à cet email.<br>
    <strong style="color:#E8701A">L'équipe Tekeche</strong>
  </p>
</div>`;

transporter.sendMail({
  from: '"Tekeche" <assalehervekouame@gmail.com>',
  to: 'louismartialb@gmail.com',
  subject: 'Invitation — Test fermé Tekeche (Alpha)',
  html,
}).then(info => console.log('Sent to louismartialb@gmail.com — ' + info.messageId))
  .catch(e => { console.error('Failed:', e.message); process.exit(1); });
