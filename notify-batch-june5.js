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

  <h2 style="color:#E8701A;margin:0 0 4px">Tekeche — Mises à jour 🚀</h2>
  <p style="color:#9CA3AF;font-size:14px;margin:0 0 24px">Fermez et rouvrez l'application pour obtenir toutes les nouveautés</p>

  <p style="margin:0 0 24px">Bonjour,</p>
  <p style="margin:0 0 24px">Plusieurs nouvelles fonctionnalités sont disponibles dans Tekeche. <strong style="color:#F9FAFB">Fermez et rouvrez l'app</strong> pour les obtenir automatiquement.</p>

  <!-- Food delivery -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 12px;border-left:4px solid #E8701A">
    <p style="margin:0 0 6px;color:#E8701A;font-weight:700;font-size:15px">🍔 Livraison de repas</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      Commandez vos repas directement depuis Tekeche. Nouvel onglet <strong style="color:#F9FAFB">"Livraison"</strong> dans l'application — parcourez les restaurants, ajoutez au panier et suivez votre commande en temps réel. Le livreur peut vous contacter directement par chat.
    </p>
  </div>

  <!-- Driver delivery -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 12px;border-left:4px solid #3B82F6">
    <p style="margin:0 0 6px;color:#3B82F6;font-weight:700;font-size:15px">🛵 Chauffeurs — Livraisons disponibles</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      Les chauffeurs peuvent désormais accepter des livraisons de repas depuis l'onglet <strong style="color:#F9FAFB">"Livraison"</strong> dans l'app chauffeur. Gérez chaque étape de la livraison et chattez avec le client directement depuis l'app.
    </p>
  </div>

  <!-- Trip reviews -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 12px;border-left:4px solid #22C55E">
    <p style="margin:0 0 6px;color:#22C55E;font-weight:700;font-size:15px">⭐ Évaluation des courses</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      Le système de notation fonctionne maintenant correctement. À la fin de chaque course, une fenêtre s'affiche pour noter votre chauffeur — vos retours nous aident à améliorer le service.
    </p>
  </div>

  <!-- OTP keypad -->
  <div style="background:#111827;border-radius:12px;padding:18px;margin:0 0 24px;border-left:4px solid #8B5CF6">
    <p style="margin:0 0 6px;color:#8B5CF6;font-weight:700;font-size:15px">🔑 Connexion améliorée</p>
    <p style="margin:0;color:#D1D5DB;font-size:14px;line-height:1.6">
      L'écran de saisie du code de vérification a été redesigné pour une meilleure lisibilité sur tous les appareils.
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
  subject: 'Tekeche — Livraison de repas, évaluations et plus 🚀',
  html,
}).then(info => console.log(`Sent to ${TESTERS.length} testers — ${info.messageId}`))
  .catch(e => { console.error('Failed:', e.message); process.exit(1); });
