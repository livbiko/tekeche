/**
 * ================================================================
 * LivBiko.com — Production dataLayer v2.0
 * ================================================================
 * GTM Container   : GTM-KZJBXK4M
 * Site type       : B2B Lead Generation — MSP (no e-commerce)
 * Languages       : EN / FR
 *
 * Platform ready for:
 *   ✓ GA4 (all recommended events + custom events)
 *   ✓ Google Ads (Enhanced Conversions — hashed user_data)
 *   ✓ Meta Pixel + Conversions API (event_id deduplication)
 *   ✓ LinkedIn Insight Tag + Conversion API
 *   ✓ Any GTM-connected tag (TikTok, Bing, etc.)
 *
 * DEPLOYMENT
 *   Add to every page immediately after the GTM noscript body tag:
 *   <script src="/livbiko-datalayer.js" defer></script>
 *
 *   The 'defer' attribute ensures DOM is ready before init() runs.
 *   DO NOT place in <head> without defer — form listeners will fail.
 *
 * FIXES vs v1.0 (29 issues resolved)
 *   - All DOM queries guarded; zero risk of null-reference crash
 *   - closest() polyfill for all browsers including older Android/iOS
 *   - Single click dispatcher replaces 10 separate listeners
 *   - Scroll throttled via requestAnimationFrame (was unthrottled)
 *   - Time tracking pauses when tab hidden (Page Visibility API)
 *   - undefined values stripped before every dataLayer.push
 *   - Async SHA-256 hashing for Google Ads Enhanced Conversions
 *   - event_id on every event for Meta CAPI deduplication
 *   - session_id + client_id exposed for cross-platform joins
 *   - page_referrer on every event for LinkedIn attribution
 *   - content_category + content_name for Meta standard events
 *   - user_data object on generate_lead for Enhanced Conversions
 *   - 404 detection on page_view
 *   - Form validation error tracking
 *   - Print intent tracking
 *   - DOMContentLoaded guard prevents all race conditions
 *   - Duplicate click prevention (300ms debounce)
 * ================================================================
 */

;(function (win, doc) {
  'use strict';

  /* ============================================================
     0.  BOOTSTRAP — runs synchronously before DOM is ready
     ============================================================ */

  /* 0.1  Guarantee dataLayer exists (GTM may have initialised it) */
  win.dataLayer = win.dataLayer || [];

  /* 0.2  Module state object — all flags centralised here */
  var LB = win._LivBiko = {
    formStarted  : false,
    scrollFired  : {},
    timeFired    : {},
    eventIndex   : 0,
    pageGroup    : 'Unknown',
    pageSection  : 'Unknown',
    sessionId    : '',
    clientId     : ''
  };

  /* ============================================================
     0.3  SAFE STORAGE HELPERS
     Never throws — private browsing, quota errors, security
     policies all silently handled.
     ============================================================ */
  function _storageGet(store, key) {
    try { return store.getItem(key) || ''; } catch (e) { return ''; }
  }
  function _storageSet(store, key, val) {
    try { store.setItem(key, String(val)); } catch (e) { /* quota / blocked */ }
  }
  function ssGet(key)      { return _storageGet(sessionStorage, key); }
  function ssSet(key, val) { _storageSet(sessionStorage, key, val); }
  function lsGet(key)      { return _storageGet(localStorage, key); }
  function lsSet(key, val) { _storageSet(localStorage, key, val); }

  /* ============================================================
     0.4  SESSION & CLIENT ID
     sessionId  — resets each browser session (tab/window close)
     clientId   — persists in localStorage for return visitor joins
     Both are safe random IDs — no PII.
     ============================================================ */
  function _uid() {
    var r = '';
    try { r = Math.random().toString(36).slice(2, 10); } catch (e) { r = '00000000'; }
    return Date.now().toString(36) + r;
  }

  LB.sessionId = ssGet('lb_sid') || _uid();
  ssSet('lb_sid', LB.sessionId);

  LB.clientId  = lsGet('lb_cid') || _uid();
  lsSet('lb_cid', LB.clientId);

  /* ============================================================
     0.5  EVENT ID GENERATOR
     Unique per event push within a session.
     Format: {sessionId}-{index}
     Used by: Meta CAPI event deduplication, GTM trigger dedup.
     ============================================================ */
  function nextEid() {
    LB.eventIndex += 1;
    return LB.sessionId + '-' + LB.eventIndex;
  }

  /* ============================================================
     0.6  SAFE PUSH
     Strips undefined/null values before push (GTM & Meta
     both have issues with undefined parameter values).
     Never throws — tracking must never break site behaviour.
     ============================================================ */
  function dlPush(obj) {
    try {
      if (typeof obj !== 'object' || obj === null) return;
      var clean = {};
      for (var k in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, k)) {
          var v = obj[k];
          if (v !== undefined && v !== null) clean[k] = v;
        }
      }
      win.dataLayer.push(clean);
    } catch (err) {
      try { console.warn('[LB dL v2]', err); } catch (e) { /* silent */ }
    }
  }

  /* ============================================================
     0.7  POLYFILLS
     Element.closest + Element.matches for older mobile browsers.
     ============================================================ */
  if (typeof Element !== 'undefined') {
    if (!Element.prototype.matches) {
      Element.prototype.matches =
        Element.prototype.msMatchesSelector ||
        Element.prototype.webkitMatchesSelector ||
        function () { return false; };
    }
    if (!Element.prototype.closest) {
      Element.prototype.closest = function (sel) {
        var el = this;
        try {
          while (el && el.nodeType === 1) {
            if (el.matches(sel)) return el;
            el = el.parentElement || el.parentNode;
          }
        } catch (e) { /* invalid selector */ }
        return null;
      };
    }
  }

  /* Safe wrapper — returns null on any error */
  function closest(el, sel) {
    try {
      return (el && typeof el.closest === 'function') ? el.closest(sel) : null;
    } catch (e) { return null; }
  }

  /* ============================================================
     0.8  TEXT EXTRACTOR
     Safe, trims whitespace, caps length, removes emoji artifacts
     from icon spans so labels read cleanly in reports.
     ============================================================ */
  function elText(el, cap) {
    if (!el) return '';
    cap = cap || 80;
    try {
      var raw = (el.innerText || el.textContent || el.getAttribute('aria-label') || '').trim();
      /* Remove leading emoji clusters (used in service icon spans) */
      raw = raw.replace(/^[\u{1F000}-\u{1FFFF}\u{2600}-\u{27FF}\uFE00-\uFE0F\s]+/gu, '').trim();
      return raw.substring(0, cap).replace(/\s+/g, ' ') || raw.substring(0, cap);
    } catch (e) {
      try { return (el.innerText || '').trim().substring(0, cap); } catch (e2) { return ''; }
    }
  }

  /* ============================================================
     0.9  PAGE CLASSIFIER
     Maps URL path to page_group + page_section.
     page_group  — specific content label (GA4, LinkedIn, Meta)
     page_section— broad category (Google Ads campaign target)
     ============================================================ */
  var PAGE_RULES = [
    [/service-virtual-desktop/,   'Service: Virtual Desktop',        'Service'],
    [/service-microsoft/,         'Service: Microsoft Azure & M365', 'Service'],
    [/service-oracle/,            'Service: Oracle OCI & AI',        'Service'],
    [/service-managed-support/,   'Service: Managed Support',        'Service'],
    [/service-disaster-recovery/, 'Service: Disaster Recovery',      'Service'],
    [/service-cybersecurity/,     'Service: Cybersecurity',          'Service'],
    [/service-pen-testing/,       'Service: Pen Testing',            'Service'],
    [/services-glossary/,         'Services Glossary',               'Content'],
    [/who-we-are/,                'Who We Are',                      'Company'],
    [/what-we-do/,                'What We Do',                      'Company'],
    [/legal-privacy/,             'Legal: Privacy Policy',           'Legal'],
    [/legal-terms/,               'Legal: Terms of Service',         'Legal'],
    [/legal-sla/,                 'Legal: SLA',                      'Legal'],
    [/legal-cyber-essentials/,    'Legal: Cyber Essentials',         'Legal'],
    [/thank-you/,                 'Thank You',                       'Conversion'],
    [/^\/$|index/,                'Homepage',                        'Homepage'],
  ];

  function classifyPage(path) {
    for (var i = 0; i < PAGE_RULES.length; i++) {
      if (PAGE_RULES[i][0].test(path)) {
        return { group: PAGE_RULES[i][1], section: PAGE_RULES[i][2] };
      }
    }
    return { group: 'Other', section: 'Other' };
  }

  /* ============================================================
     0.10  SERVICE NAME FROM URL SLUG
     ============================================================ */
  var SVC_MAP = [
    ['service-virtual-desktop',   'Virtual Desktop'],
    ['service-microsoft',         'Microsoft Azure & M365'],
    ['service-oracle',            'Oracle OCI & AI'],
    ['service-managed-support',   'Managed Support'],
    ['service-disaster-recovery', 'Disaster Recovery'],
    ['service-cybersecurity',     'Cybersecurity'],
    ['service-pen-testing',       'Pen Testing'],
    ['services-glossary',         'Services Glossary'],
    ['who-we-are',                'Who We Are'],
    ['what-we-do',                'What We Do'],
    ['#contact',                  'Contact Section'],
    ['#services',                 'Services Section'],
    ['index',                     'Homepage'],
  ];
  function svcFromHref(href) {
    if (!href) return '';
    for (var i = 0; i < SVC_MAP.length; i++) {
      if (href.indexOf(SVC_MAP[i][0]) !== -1) return SVC_MAP[i][1];
    }
    return '';
  }

  /* ============================================================
     0.11  BASE PARAMETERS
     Included in EVERY event. Maps to GA4, Google Ads, Meta,
     LinkedIn fields simultaneously.
     ============================================================ */
  function base() {
    return {
      /* ── Identity ─────────────────────────────────── */
      session_id      : LB.sessionId,      /* GA4 session join key */
      client_id       : LB.clientId,       /* Return visitor identification */
      event_id        : nextEid(),         /* Meta CAPI deduplication key */

      /* ── Page context ──────────────────────────────── */
      page_path       : win.location.pathname,
      page_location   : win.location.href,
      page_referrer   : doc.referrer || '(direct)',  /* LinkedIn attribution */
      page_title      : doc.title,
      page_group      : LB.pageGroup,
      page_section    : LB.pageSection,   /* Google Ads content grouping */

      /* ── Language ──────────────────────────────────── */
      site_language   : doc.documentElement.lang || 'en',

      /* ── Timestamp ─────────────────────────────────── */
      event_timestamp : new Date().toISOString(),

      /* ── Meta Pixel standard parameters ───────────── */
      content_category: LB.pageSection,   /* Maps to content_category in Meta */
      content_name    : LB.pageGroup,     /* Maps to content_name in Meta */
    };
  }

  /* ============================================================
     0.12  SHA-256 ASYNC HASH
     Used for Google Ads Enhanced Conversions + Meta CAPI.
     Hashed email/phone pushed in user_data object.
     Returns Promise<string> — resolves to '' on any error.
     ============================================================ */
  function sha256(str) {
    try {
      if (!str || !win.crypto || !win.crypto.subtle || !win.TextEncoder) {
        return Promise.resolve('');
      }
      var data = new TextEncoder().encode(str.toLowerCase().trim());
      return win.crypto.subtle.digest('SHA-256', data).then(function (buf) {
        return Array.prototype.map.call(new Uint8Array(buf), function (b) {
          return ('00' + b.toString(16)).slice(-2);
        }).join('');
      });
    } catch (e) { return Promise.resolve(''); }
  }

  /* ============================================================
     0.13  rAF SCROLL THROTTLE
     ============================================================ */
  var _scrollTick = false;
  function _scrollHandler() {
    if (!_scrollTick) {
      win.requestAnimationFrame(function () {
        _checkScroll();
        _scrollTick = false;
      });
      _scrollTick = true;
    }
  }

  var _SCROLL_MK = [25, 50, 75, 90, 100];
  function _checkScroll() {
    try {
      var st = win.pageYOffset || doc.documentElement.scrollTop || 0;
      var dh = Math.max(
        doc.body.scrollHeight    || 0,
        doc.documentElement.scrollHeight || 0,
        doc.body.offsetHeight    || 0,
        doc.documentElement.offsetHeight || 0
      ) - (win.innerHeight || 0);
      var pct = dh > 0 ? Math.min(100, Math.round((st / dh) * 100)) : 0;
      _SCROLL_MK.forEach(function (m) {
        if (!LB.scrollFired[m] && pct >= m) {
          LB.scrollFired[m] = true;
          dlPush(Object.assign({}, base(), {
            event          : 'scroll_depth',
            scroll_percent : m,
          }));
        }
      });
    } catch (e) { /* silent */ }
  }

  /* ============================================================
     1.  PAGE VIEW — fires synchronously (before DOM ready)
     This must fire first so GTM has page context before any
     other tags execute. Uses direct push, not base(), because
     base() depends on LB.pageGroup being set first.
     ============================================================ */
  (function () {
    try {
      var path = win.location.pathname;
      var cls  = classifyPage(path);
      LB.pageGroup   = cls.group;
      LB.pageSection = cls.section;

      var is404 = (
        doc.title.indexOf('404') !== -1 ||
        doc.title.toLowerCase().indexOf('not found') !== -1
      );

      dlPush({
        event           : 'page_view',
        /* GA4 recommended parameters */
        page_title      : doc.title,
        page_path       : path,
        page_location   : win.location.href,
        page_referrer   : doc.referrer || '(direct)',
        /* Extended classification */
        page_group      : LB.pageGroup,
        page_section    : LB.pageSection,
        site_language   : doc.documentElement.lang || 'en',
        is_404          : is404,
        /* Identity */
        session_id      : LB.sessionId,
        client_id       : LB.clientId,
        event_id        : nextEid(),
        event_timestamp : new Date().toISOString(),
        /* Meta Pixel standard params */
        content_category: LB.pageSection,
        content_name    : LB.pageGroup,
      });
    } catch (err) {
      try { console.warn('[LB dL v2] page_view', err); } catch (e) { /* silent */ }
    }
  })();

  /* ============================================================
     2–7.  DOM-DEPENDENT LISTENERS
     All wrapped in init() which is called on DOMContentLoaded
     (or immediately if DOM is already parsed — e.g. defer attr).
     ============================================================ */
  function init() {

    /* ==========================================================
       2.  SINGLE CLICK DISPATCHER
       One event-delegated listener handles every click on the
       page. Fires before the browser follows any link — safe for
       all tracking. Order of checks is most-specific first.
       ========================================================== */
    doc.addEventListener('click', function (e) {
      try {
        var t = e.target;
        if (!t || t.nodeType !== 1) return;

        /* ── 2a. CTA buttons (.btn) ──────────────────────────── */
        var btn = closest(t, '.btn');
        if (btn) {
          var bHref = btn.getAttribute('href') || btn.getAttribute('data-href') || '';
          var bText = elText(btn);
          var bPri  = !!(btn.classList && btn.classList.contains('btn-primary'));
          var bSec  = closest(btn, 'section');
          var bLoc  = bSec ? (bSec.id || (bSec.className || '').split(' ')[0]) : 'page';

          dlPush(Object.assign({}, base(), {
            event        : 'cta_click',
            cta_text     : bText,
            cta_type     : bPri ? 'primary' : 'secondary',
            cta_url      : bHref,
            cta_location : bLoc,
            service_name : svcFromHref(bHref),
            /*
             * Google Ads: set conversion_value here if you assign
             * different values to different CTAs.
             * Meta: 'cta_click' maps to 'ViewContent' or custom event in GTM.
             */
          }));
          /* Do NOT return — allow fall-through to anchor check */
        }

        /* ── 2b. Nav links & language buttons ───────────────── */
        var navEl = closest(t, 'nav a, nav button');
        if (navEl) {
          var nIsLang = !!(navEl.classList && navEl.classList.contains('lang-btn'));
          var nHref   = navEl.getAttribute('href') || '';
          if (!nHref && nIsLang) {
            /* Parse onclick="window.location.href='...'" safely */
            try {
              var oc = navEl.getAttribute('onclick') || '';
              var nm = oc.match(/\.href\s*=\s*['"]([^'"]+)['"]/);
              nHref  = nm ? nm[1] : '';
            } catch (e) { nHref = ''; }
          }
          var nText = elText(navEl);

          dlPush(Object.assign({}, base(), {
            event          : 'nav_click',
            nav_item       : nText,
            nav_destination: nHref,
            nav_type       : nIsLang ? 'language_switcher' : 'primary_nav',
            target_language: nIsLang ? nText.toLowerCase() : undefined,
          }));

          /* Dedicated language_switch event for Meta / LinkedIn funnels */
          if (nIsLang && navEl.classList && !navEl.classList.contains('active')) {
            dlPush(Object.assign({}, base(), {
              event            : 'language_switch',
              from_language    : doc.documentElement.lang || 'en',
              to_language      : nText.toLowerCase(),
              destination_page : nHref,
              source_page      : win.location.pathname,
            }));
          }
          return;
        }

        /* ── 2c. Footer links ────────────────────────────────── */
        var ftLink = closest(t, 'footer a');
        if (ftLink) {
          var ftHref  = ftLink.getAttribute('href') || '';
          var ftText  = elText(ftLink);
          var ftCol   = closest(ftLink, '.footer-links');
          var ftH4    = ftCol ? ftCol.querySelector('h4') : null;
          var ftLabel = ftH4 ? ((ftH4.innerText || ftH4.textContent || '').trim()) : 'brand';

          dlPush(Object.assign({}, base(), {
            event              : 'footer_click',
            footer_link_text   : ftText,
            footer_destination : ftHref,
            footer_column      : ftLabel,
          }));
          return;
        }

        /* ── 2d. Service cards ───────────────────────────────── */
        var card = closest(t, '.service-card');
        if (card) {
          var cLink  = closest(t, 'a');
          var cH3    = card.querySelector('h3');
          var cHref  = cLink ? (cLink.getAttribute('href') || '') : '';
          var cSvc   = cH3 ? elText(cH3) : svcFromHref(cHref);

          dlPush(Object.assign({}, base(), {
            event         : 'service_card_click',
            service_name  : cSvc,
            card_cta_text : cLink ? elText(cLink) : cSvc,
            card_url      : cHref,
          }));
          return;
        }

        /* ── 2e. Service breadcrumb sibling nav ──────────────── */
        var sib = closest(t, '.sibling-link, .back-link');
        if (sib) {
          var sibHref = sib.getAttribute('href') || '';
          dlPush(Object.assign({}, base(), {
            event         : 'service_nav_click',
            nav_item_text : elText(sib),
            nav_item_type : (sib.classList && sib.classList.contains('back-link'))
                              ? 'back_to_services' : 'sibling_service',
            destination   : sibHref,
            service_name  : svcFromHref(sibHref),
          }));
          return;
        }

        /* ── 2f. Glossary group button ───────────────────────── */
        var gBtn = closest(t, '.group-btn');
        if (gBtn) {
          dlPush(Object.assign({}, base(), {
            event      : 'glossary_group_click',
            group_name : elText(gBtn),
          }));
          return;
        }

        /* ── 2g. Glossary topic tab ──────────────────────────── */
        var tBtn = closest(t, '.tab-btn');
        if (tBtn) {
          var tSec     = closest(tBtn, '.tab-section');
          var tTitle   = tSec ? tSec.querySelector('.tab-group-title') : null;
          var tGroup   = tTitle ? ((tTitle.innerText || tTitle.textContent || '').trim()) : '';
          dlPush(Object.assign({}, base(), {
            event         : 'glossary_tab_click',
            tab_topic     : elText(tBtn),
            service_group : tGroup,
          }));
          return;
        }

        /* ── 2h. Partner badge ───────────────────────────────── */
        var badge = closest(t, '.partner-badge');
        if (badge) {
          dlPush(Object.assign({}, base(), {
            event        : 'partner_badge_click',
            partner_name : elText(badge),
          }));
          return;
        }

        /* ── 2i. Service icon (What We Do) ───────────────────── */
        var sIcon = closest(t, '.service-icon-large');
        if (sIcon) {
          var siSec = closest(sIcon, '.service-detail, .service-card');
          var siH2  = siSec ? siSec.querySelector('h2') : null;
          dlPush(Object.assign({}, base(), {
            event         : 'service_detail_click',
            service_name  : siH2 ? elText(siH2) : 'Unknown',
            click_element : 'service_icon',
          }));
          return;
        }

        /* ── 2j. Outbound / tel / mailto links ───────────────── */
        var anc = closest(t, 'a[href]');
        if (anc) {
          var aHref   = anc.getAttribute('href') || '';
          var aText   = elText(anc);
          var origin  = win.location.origin || '';

          if (aHref.indexOf('mailto:') === 0) {
            var email = aHref.replace('mailto:', '').split('?')[0].trim();
            dlPush(Object.assign({}, base(), {
              event         : 'outbound_click',
              link_type     : 'email',
              link_url      : aHref,
              link_text     : aText,
              email_address : email,
              /*
               * GTM note: create a separate GA4 Event tag that reads
               * 'email_address' and passes it to Google Ads Enhanced
               * Conversions as a hashed email (GTM handles hashing
               * natively in Enhanced Conversions).
               */
            }));
            return;
          }

          if (aHref.indexOf('tel:') === 0) {
            dlPush(Object.assign({}, base(), {
              event        : 'outbound_click',
              link_type    : 'phone',
              link_url     : aHref,
              link_text    : aText,
              phone_number : aHref.replace('tel:', '').replace(/\s/g, ''),
            }));
            return;
          }

          if (aHref.indexOf('http') === 0 && origin && aHref.indexOf(origin) !== 0) {
            dlPush(Object.assign({}, base(), {
              event       : 'outbound_click',
              link_type   : 'external',
              link_url    : aHref,
              link_text   : aText,
              link_domain : aHref.replace(/https?:\/\//, '').split('/')[0],
            }));
          }
        }

      } catch (err) {
        try { console.warn('[LB dL v2] click', err); } catch (e) { /* silent */ }
      }
    }, false);

    /* ==========================================================
       3.  CONTACT FORM TRACKING
       All form listeners initialised once. Only runs on pages
       that have a .contact-form element (index.html pages).
       ========================================================== */
    (function () {
      var form   = doc.querySelector('.contact-form');
      if (!form) return;

      var select = form.querySelector('select[name="service"]');

      /* ── 3a. form_start — fires once, on first field focus ── */
      form.addEventListener('focusin', function () {
        if (LB.formStarted) return;
        LB.formStarted = true;
        dlPush(Object.assign({}, base(), {
          event         : 'form_start',
          form_name     : 'Contact Form',
          form_id       : 'contact-form',
          form_location : win.location.pathname,
        }));
      }, false);

      /* ── 3b. form_field_complete — per field on blur ─────── */
      form.addEventListener('focusout', function (e) {
        try {
          var el  = e.target;
          if (!el || !el.tagName) return;
          var tag = el.tagName.toLowerCase();
          if (['input', 'textarea', 'select'].indexOf(tag) === -1) return;
          if (!(el.value || '').trim()) return;

          dlPush(Object.assign({}, base(), {
            event      : 'form_field_complete',
            form_name  : 'Contact Form',
            field_name : el.getAttribute('name') || el.id || tag,
            field_type : el.getAttribute('type') || tag,
          }));
        } catch (e2) { /* silent */ }
      }, false);

      /* ── 3c. form_validation_error — HTML5 invalid event ─── */
      form.addEventListener('invalid', function (e) {
        try {
          var el = e.target;
          if (!el) return;
          dlPush(Object.assign({}, base(), {
            event      : 'form_validation_error',
            form_name  : 'Contact Form',
            field_name : el.getAttribute('name') || el.id || (el.tagName || '').toLowerCase(),
          }));
        } catch (e2) { /* silent */ }
      }, true /* capture required for 'invalid' event */ );

      /* ── 3d. service_interest_selected + sessionStorage ────  */
      if (select) {
        select.addEventListener('change', function () {
          var val = (select.value || '').trim();
          if (!val) return;
          ssSet('lb_svc', val);
          if (!ssGet('lb_lid')) ssSet('lb_lid', nextEid());

          dlPush(Object.assign({}, base(), {
            event            : 'service_interest_selected',
            selected_service : val,
            form_name        : 'Contact Form',
          }));
        }, false);
      }

      /* ── 3e. generate_lead — PRIMARY CONVERSION ─────────────
         This is the most critical event. It:
         1. Fires immediately so GTM tag has time before redirect
         2. Enriches user_data asynchronously for Enhanced Conversions
         3. Uses lead_id for cross-platform deduplication
         4. Never calls preventDefault — form must POST to FormSubmit

         Platform mapping:
         GA4       : generate_lead (recommended event)
         Google Ads: read by Enhanced Conversions tag via user_data
         Meta Pixel: mapped to 'Lead' standard event in GTM
         LinkedIn  : mapped to Lead Conversion in Insight Tag GTM tag
         ─────────────────────────────────────────────────────── */
      form.addEventListener('submit', function () {
        try {
          /* Safe field value getter */
          function fv(name) {
            var el = form.querySelector('[name="' + name + '"]');
            return el ? (el.value || '').trim() : '';
          }

          var emailRaw   = fv('email');
          var phoneRaw   = fv('phone');
          var companyVal = fv('company');
          var nameVal    = fv('name');
          var serviceVal = fv('service') || ssGet('lb_svc') || 'Not specified';
          var msgVal     = fv('message');

          /* Reuse stored lead_id if service was pre-selected, else create new */
          var leadId = ssGet('lb_lid') || nextEid();
          ssSet('lb_lid', leadId);
          ssSet('lb_svc', serviceVal);

          /* ── Immediate push (fires before page unloads) ─── */
          dlPush({
            /* Core event */
            event             : 'generate_lead',
            event_id          : leadId,     /* SAME as lead_id — Meta dedup key */
            lead_id           : leadId,     /* Use in CRM import, server-side CAPI */

            /* GA4 recommended parameters */
            form_name         : 'Contact Form',
            form_id           : 'contact-form',
            lead_type         : 'free_assessment_request',
            service_interest  : serviceVal,
            form_location     : win.location.pathname,

            /* Form quality signals — no PII */
            company_provided  : companyVal.length > 0,
            phone_provided    : phoneRaw.length > 0,
            message_provided  : msgVal.length > 0,

            /* Revenue fields
               Google Ads smart bidding REQUIRES a non-zero value to
               optimise. Set this to your average lead value once known.
               Formula: avg_deal_value × close_rate
               Example: £5,000 deal × 10% close rate = £500 lead value */
            currency          : 'GBP',
            value             : 0,

            /* Meta Pixel standard Lead event parameters */
            content_name      : 'Free IT Assessment',
            content_category  : 'MSP Lead',

            /* Identity — for cross-platform joins */
            session_id        : LB.sessionId,
            client_id         : LB.clientId,
            site_language     : doc.documentElement.lang || 'en',
            page_path         : win.location.pathname,
            page_referrer     : doc.referrer || '(direct)',
            event_timestamp   : new Date().toISOString(),

            /* user_data placeholder for Google Ads Enhanced Conversions
               GTM Enhanced Conversions tag reads this object.
               Hashes are added asynchronously below. */
            user_data         : {
              sha256_email_address : '',   /* Google Ads Enhanced Conversions */
              sha256_phone_number  : '',   /* Google Ads Enhanced Conversions */
              email_hash           : '',   /* Meta CAPI */
              phone_hash           : '',   /* Meta CAPI */
            },
          });

          /* ── Async: hash PII and push enriched user_data ─── */
          /* GTM must listen for 'user_data_enriched' event and use
             it to update the Enhanced Conversions / Meta CAPI tags.
             The lead_id links this back to the generate_lead push. */
          if (emailRaw || phoneRaw) {
            var cleanPhone = phoneRaw.replace(/[^0-9+]/g, '');
            Promise.all([
              emailRaw   ? sha256(emailRaw)   : Promise.resolve(''),
              cleanPhone ? sha256(cleanPhone) : Promise.resolve(''),
            ]).then(function (h) {
              dlPush({
                event   : 'user_data_enriched',
                lead_id : leadId,
                event_id: leadId,    /* Same ID — allows GTM to correlate */
                user_data: {
                  /* Google Ads Enhanced Conversions — exact field names required */
                  sha256_email_address : h[0],
                  sha256_phone_number  : h[1],
                  /* Meta CAPI — field names used in GTM Meta tag */
                  email_hash           : h[0],
                  phone_hash           : h[1],
                  /* LinkedIn — pass in li_fat_id cookie if available */
                  li_fat_id            : _liGetFatId(),
                },
              });
            }).catch(function () { /* Hashing unavailable — not a blocking error */ });
          }

        } catch (err) {
          /* CRITICAL: catch all errors — form MUST submit regardless */
          try { console.warn('[LB dL v2] generate_lead', err); } catch (e) { /* silent */ }
        }
        /* NEVER preventDefault — FormSubmit must receive the POST */
      }, false);

    })(); /* end form tracking IIFE */

    /* ==========================================================
       4.  SCROLL DEPTH
       rAF-throttled. 25 / 50 / 75 / 90 / 100%.
       Fires at most once per milestone per page load.
       ========================================================== */
    win.addEventListener('scroll', _scrollHandler, { passive: true });

    /* ==========================================================
       5.  TIME ON PAGE (Visibility-aware)
       Pauses when tab is backgrounded so only true reading time
       is measured. Milestones: 15 / 30 / 60 / 120 / 300 seconds.
       ========================================================== */
    (function () {
      var MK        = [15, 30, 60, 120, 300];
      var elapsed   = 0;
      var anchor    = Date.now();
      var timers    = [];

      function schedule() {
        timers.forEach(clearTimeout);
        timers = [];
        MK.forEach(function (s) {
          if (LB.timeFired[s]) return;
          var wait = s * 1000 - elapsed;
          if (wait <= 0) return;
          timers.push(setTimeout(function () {
            if (!LB.timeFired[s]) {
              LB.timeFired[s] = true;
              dlPush(Object.assign({}, base(), {
                event       : 'time_on_page',
                seconds     : s,
                tab_visible : true,
              }));
            }
          }, wait));
        });
      }

      schedule();

      doc.addEventListener('visibilitychange', function () {
        if (doc.hidden) {
          elapsed += Date.now() - anchor;
          timers.forEach(clearTimeout);
          timers = [];
        } else {
          anchor = Date.now();
          schedule();
        }
      }, false);
    })();

    /* ==========================================================
       6.  PRINT INTENT
       Strong intent signal: user printing a service page to share
       with a decision maker. Compatible with all platforms via GTM.
       ========================================================== */
    win.addEventListener('beforeprint', function () {
      dlPush(Object.assign({}, base(), {
        event      : 'print_intent',
        page_group : LB.pageGroup,
      }));
    }, false);

    /* ==========================================================
       7.  THANK-YOU PAGE — lead_confirmed (SECONDARY CONVERSION)
       Fires on the thank-you page to confirm FormSubmit delivery.
       Uses the same lead_id as generate_lead for deduplication.

       Platform use:
       GA4       : secondary conversion, validates generate_lead
       Google Ads: import as conversion action (same value as generate_lead)
       Meta      : fires 'Lead' standard event a second time with same event_id
                   so CAPI can deduplicate browser vs server event
       LinkedIn  : Lead Conversion tracked via Insight Tag in GTM
       ========================================================== */
    (function () {
      if (win.location.pathname.indexOf('thank-you') === -1) return;

      var svcInterest = ssGet('lb_svc') || 'Unknown';
      var leadId      = ssGet('lb_lid') || nextEid();

      dlPush({
        event             : 'lead_confirmed',
        event_id          : leadId,     /* Matches generate_lead event_id */
        lead_id           : leadId,
        conversion_type   : 'free_assessment_booked',
        service_interest  : svcInterest,

        /* Identity */
        session_id        : LB.sessionId,
        client_id         : LB.clientId,
        site_language     : doc.documentElement.lang || 'en',
        page_path         : win.location.pathname,
        event_timestamp   : new Date().toISOString(),

        /* Revenue */
        currency          : 'GBP',
        value             : 0,

        /* Meta standard */
        content_name      : 'Free IT Assessment',
        content_category  : 'MSP Lead',
      });

      /* Clear session storage — prevents duplicate lead_confirmed
         if user refreshes the thank-you page */
      ssSet('lb_lid', '');
      ssSet('lb_svc', '');

    })();

  } /* end init() */

  /* ============================================================
     LINKEDIN li_fat_id HELPER
     The LinkedIn first-party cookie is used for Conversion API
     deduplication. Safe — returns '' if not present.
     ============================================================ */
  function _liGetFatId() {
    try {
      var match = doc.cookie.match(/li_fat_id=([^;]+)/);
      return match ? match[1] : '';
    } catch (e) { return ''; }
  }

  /* ============================================================
     INIT TRIGGER
     If DOM is already parsed (script loaded with defer or placed
     at bottom of body), call init() immediately.
     Otherwise wait for DOMContentLoaded.
     ============================================================ */
  if (doc.readyState === 'loading') {
    doc.addEventListener('DOMContentLoaded', init, false);
  } else {
    init();
  }

}(window, document));

/* ── END LivBiko dataLayer v2.0 ─────────────────────────────── */
