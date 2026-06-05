require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/dotenv').config({ path: 'C:/inetpub/wwwroot/tekeche/tekeche-api/.env' });
const nodemailer = require('C:/inetpub/wwwroot/tekeche/tekeche-api/node_modules/nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS },
});

const TESTERS = [
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
  'adelabikouame@gmail.com',
];

const html = `
<div style="font-family:-apple-system,Arial,sans-serif;max-width:580px;margin:0 auto;background:#1A1A2E;color:#F9FAFB;padding:32px;border-radius:16px">

  <h2 style="color:#E8701A;margin:0 0 4px">Tekeche — Mises à jour Livraison 🍔</h2>
  <p style="color:#9CA3AF;font-size:14px;margin:0 0 24px">Fermez et rouvrez l'application pour obtenir toutes les nouveautés</p>

  <p style="margin:0 0 24px">Bonjour,</p>
  <p style="margin:0 0 24px">Voici les dernières améliorations apportées à la fonctionnalité de livraison de repas dans Tekeche.</p>

  <!-- Ratings -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 12px;border-left:4px solid #FBBF24">
    <p style="margin:0 0 6px;color:#FBBF24;font-weight:700;font-size:15px">⭐ Évaluations complètes</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      Après chaque livraison, une fenêtre d'évaluation s'affiche automatiquement pour les passagers <strong style="color:#F9FAFB">(noter le restaurant)</strong> et pour les chauffeurs <strong style="color:#F9FAFB">(noter le client)</strong>. Vos retours améliorent la qualité du service.
    </p>
  </div>

  <!-- Restaurant details -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 12px;border-left:4px solid #E8701A">
    <p style="margin:0 0 6px;color:#E8701A;font-weight:700;font-size:15px">🏪 Informations restaurant enrichies</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      La page menu de chaque restaurant affiche désormais la <strong style="color:#F9FAFB">note</strong>, les <strong style="color:#F9FAFB">horaires d'ouverture</strong> (appuyez pour voir la semaine complète) et la <strong style="color:#F9FAFB">description</strong> du restaurant.
    </p>
  </div>

  <!-- Driver delivery screen -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 24px;border-left:4px solid #3B82F6">
    <p style="margin:0 0 6px;color:#3B82F6;font-weight:700;font-size:15px">🛵 App Chauffeur — améliorations livraison</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      L'écran de livraison des chauffeurs a été amélioré avec des informations plus complètes sur chaque commande et un accès direct au chat avec le client.
    </p>
  </div>

  <div style="background:#111827;border-radius:8px;padding:14px;margin:0 0 24px">
    <p style="margin:0;color:#9CA3AF;font-size:13px">
      💡 Toutes ces mises à jour s'appliquent automatiquement en <strong style="color:#F9FAFB">fermant et rouvrant l'app</strong>. Aucun téléchargement requis.
    </p>
  </div>

  <p style="color:#6B7280;font-size:13px;margin:24px 0 0;border-top:1px solid #374151;padding-top:16px">
    Des questions ou retours ? Répondez directement à cet email.<br>
    <strong style="color:#E8701A">L'équipe Tekeche</strong>
  </p>
</div>`;

transporter.sendMail({
  from: '"Tekeche" <assalehervekouame@gmail.com>',
  to: TESTERS.join(', '),
  subject: 'Tekeche — Évaluations livraison, horaires restaurants et plus 🍔',
  html,
}).then(info => console.log(`Sent to ${TESTERS.length} testers — ${info.messageId}`))
  .catch(e => { console.error('Failed:', e.message); process.exit(1); });
