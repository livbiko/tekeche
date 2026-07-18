/* ============================================================
   Tekeche Website — Main JavaScript
   ============================================================ */

// ─── Nav scroll effect ────────────────────────────────────────
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 40);
});

// ─── Mobile menu ──────────────────────────────────────────────
const burger = document.getElementById('burger');
const mobileMenu = document.getElementById('mobile-menu');

burger?.addEventListener('click', () => {
  burger.classList.toggle('open');
  mobileMenu.classList.toggle('open');
  document.body.style.overflow = mobileMenu.classList.contains('open') ? 'hidden' : '';
});

function closeMobile() {
  burger?.classList.remove('open');
  mobileMenu?.classList.remove('open');
  document.body.style.overflow = '';
}

// ─── Intersection Observer animations ─────────────────────────
const animEls = document.querySelectorAll('[data-animate]');
const obs = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      const delay = e.target.dataset.delay || 0;
      setTimeout(() => e.target.classList.add('visible'), Number(delay));
      obs.unobserve(e.target);
    }
  });
}, { threshold: 0.15 });
animEls.forEach(el => obs.observe(el));

// ─── FAQ accordion ────────────────────────────────────────────
function toggleFaq(btn) {
  const item = btn.parentElement;
  const answer = item.querySelector('.faq-a');
  const isOpen = btn.classList.contains('open');

  // Close all
  document.querySelectorAll('.faq-q.open').forEach(q => {
    q.classList.remove('open');
    q.parentElement.querySelector('.faq-a').classList.remove('open');
  });

  // Toggle this one
  if (!isOpen) {
    btn.classList.add('open');
    answer.classList.add('open');
  }
}

// ─── Earnings calculator ─────────────────────────────────────
const hSlider = document.getElementById('h-slider');
const dSlider = document.getElementById('d-slider');

function calcEarnings() {
  if (!hSlider || !dSlider) return;
  const hours = parseInt(hSlider.value);
  const days = parseInt(dSlider.value);

  document.getElementById('h-val').textContent = hours + 'h';
  document.getElementById('d-val').textContent = days + 'j';

  const tripsPerHour = 3.5;
  const farePerTrip = 3500;
  const driverCut = 0.85;
  const daily = Math.round(hours * tripsPerHour * farePerTrip * driverCut);
  const weekly = Math.round(daily * days);
  const monthly = Math.round(weekly * 4.3);

  document.getElementById('daily').textContent = '~' + daily.toLocaleString('fr-CI') + ' FCFA';
  document.getElementById('weekly').textContent = '~' + weekly.toLocaleString('fr-CI') + ' FCFA';
  document.getElementById('monthly').textContent = monthly.toLocaleString('fr-CI');
}

hSlider?.addEventListener('input', calcEarnings);
dSlider?.addEventListener('input', calcEarnings);
calcEarnings();

// ─── Notification form ────────────────────────────────────────
async function submitNotif() {
  const emailEl = document.getElementById('notif-email');
  const msg = document.getElementById('notif-msg');
  if (!msg) return;

  const email = emailEl?.value?.trim();
  if (!email || !email.includes('@')) {
    msg.textContent = '⚠️ Veuillez entrer un email valide.';
    msg.style.color = 'rgba(255,255,255,.9)';
    return;
  }

  try {
    await fetch('https://api.tekeche.com/api/notify/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    });
    msg.textContent = '✅ Parfait ! Nous vous préviendrons dès le lancement.';
    msg.style.color = 'rgba(255,255,255,.9)';
    if (emailEl) emailEl.value = '';
  } catch {
    msg.textContent = '⚠️ Erreur réseau. Réessayez.';
    msg.style.color = 'rgba(255,100,100,.9)';
  }
}

// ─── Smooth scroll for anchor links ──────────────────────────
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    const target = document.querySelector(a.getAttribute('href'));
    if (target) {
      e.preventDefault();
      closeMobile();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
});

// ─── Active section highlight in nav ─────────────────────────
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-links a[href^="#"]');

const secObs = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      navLinks.forEach(link => {
        link.style.color = link.getAttribute('href') === '#' + e.target.id
          ? '#fff'
          : 'rgba(255,255,255,.7)';
      });
    }
  });
}, { threshold: 0.4 });

sections.forEach(s => secObs.observe(s));
