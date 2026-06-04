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

  <h2 style="color:#E8701A;margin:0 0 4px">Tekeche — Nouvelles fonctionnalités 🚀</h2>
  <p style="color:#9CA3AF;font-size:14px;margin:0 0 24px">Mise à jour disponible — fermez et rouvrez l'application</p>

  <p style="margin:0 0 20px">Bonjour,</p>
  <p style="margin:0 0 24px">L'application Tekeche vient de recevoir plusieurs nouvelles fonctionnalités. <strong style="color:#F9FAFB">Fermez et rouvrez l'app</strong> pour obtenir la mise à jour automatiquement.</p>

  <!-- Chat -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 12px;border-left:4px solid #E8701A">
    <p style="margin:0 0 6px;color:#E8701A;font-weight:700;font-size:15px">💬 Chat en temps réel</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      Discutez directement avec votre chauffeur (ou passager) pendant la course.
      Un bouton <strong style="color:#F9FAFB">"Chat"</strong> apparaît dès qu'un chauffeur est attribué.
    </p>
  </div>

  <!-- Scheduled rides -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 12px;border-left:4px solid #3B82F6">
    <p style="margin:0 0 6px;color:#3B82F6;font-weight:700;font-size:15px">🗓 Courses programmées</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      Réservez une course à l'avance (minimum 30 minutes). Retrouvez vos courses programmées
      dans le nouvel onglet <strong style="color:#F9FAFB">"Programmées"</strong> en bas de l'écran.
    </p>
  </div>

  <!-- Pool rides -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 12px;border-left:4px solid #22C55E">
    <p style="margin:0 0 6px;color:#22C55E;font-weight:700;font-size:15px">🤝 Course partagée (−25%)</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      Partagez votre course avec d'autres passagers et économisez <strong style="color:#F9FAFB">25% sur le tarif</strong>.
      L'option <strong style="color:#F9FAFB">"Partagée"</strong> sera bientôt disponible dans le choix du véhicule.
    </p>
  </div>

  <!-- Edit destination -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 24px;border-left:4px solid #8B5CF6">
    <p style="margin:0 0 6px;color:#8B5CF6;font-weight:700;font-size:15px">📍 Modifier la destination en cours de route</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      Changez votre destination après avoir réservé — avant que la course ne commence.
      Appuyez sur l'icône ✏️ à côté de la destination dans l'écran de course.
    </p>
  </div>

  <div style="background:#111827;border-radius:8px;padding:14px;margin:0 0 24px">
    <p style="margin:0;color:#9CA3AF;font-size:13px">
      💡 La mise à jour s'applique automatiquement en <strong style="color:#F9FAFB">fermant et rouvrant l'app</strong>. Aucun téléchargement requis.
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
  subject: 'Tekeche — Chat, courses programmées et plus 🚀',
  html,
}).then(info => console.log(`Sent to ${TESTERS.length} testers — ${info.messageId}`))
  .catch(e => { console.error('Failed:', e.message); process.exit(1); });
