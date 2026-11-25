# Change Register

One entry per change request (process: `CHANGE_APPROVAL.md`). Newest first. Status: requested / approved /
done / rolled back / rejected / EMERGENCY.

| CR | Title | Requested by | Class | Approved (owner's words, time UTC) | Window | Status |
|---|---|---|---|---|---|---|
| CR-2026-11-25-06 | NDP /youtube phase 2: translation system, language selector + detection; 2a French/English, 2b PT/ES/AR(RTL)/DE/IT/ZH/SW + category names migration | Claude (owner 11-25) | MEDIUM (Get-ChangeRisk said LOW) | — | — | requested |
| CR-2026-11-25-05 | Temporary BikoDC firewall rule TCP 3100 from 192.168.1.0/24 for the /youtube preview browser check (removed after) | Claude (owner 11-25 "open port 3100") | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-25-05" (11-25) | 22:50-22:52 | done - rule removed |
| CR-2026-11-25-04 | NDP /youtube phase 1 (French): "Voix indépendantes africaines" banner + "Explorer par pays" tree + read-only explorer API | Claude (owner YouTube brief 11-25) | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-25-03 the CR-2026-11-25-04" (11-25; CR-03 part not valid - no part/window) | — | in progress |
| CR-2026-11-25-03 | Build NDP images off .51 on GitHub Actions -> GHCR, light mirror job on .51 replaces the 3 Kaniko builds; then ESXi storage check (replaces CR-25-02 part A) | Claude (owner 11-25 "do it for me") | HIGH (Get-ChangeRisk said MEDIUM; new credential + pipeline) | part 1: "approve CR-2026-11-25-03 part 1 window now" (11-25 ~23:00); revised: "approve CR-2026-11-25-03 revised method: public GHCR packages, no token, window now" | part 1 11-25 22:57-23:28 | part 1 done (first night to check); part 2 later |
| CR-2026-11-25-02 | etcd disk on dr-rke2 (.51): (A) gentler nightly web build + schedule spread + measure; (B) dedicated virtual disk for etcd | Claude (owner asked 11-25; follow-up 1 of CR-2026-11-20-02) | A: MEDIUM, B: HIGH (Get-ChangeRisk said MEDIUM) | A: "approve CR-2026-11-25-02 part A" (11-25) | B: needs a window | A ROLLED BACK 11-25 22:01 (worker runs timed out during the test build); B requested |
| CR-2026-11-25-01 | Uptime check OUTSIDE the RKE2 cluster: scheduled task on BikoDC, 6 public hostnames every 2 min, Brevo mail on DOWN/UP | Claude (follow-up 1 of CR-2026-11-20-02) | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-25-01" (11-25) | — | done 11-25 21:35 |
| CR-2026-11-20-02 | EMERGENCY: NDP (+ every site served from on-prem RKE2 .51) down 04:24-13:18 UTC - etcd on .51 hung; etcd killed + rke2-server restarted | Claude (owner: "why all my websites are down again ? fix that") | EMERGENCY | owner "fix that" 13:07; emergency rule (minimum action) | 13:14-13:18 | done - restored 13:18 |
| CR-2026-11-20-01 | NDP discovery: (A) link-mining on all regions + 6-hourly run for countries with <3 active publishers; (B) search-API discovery (needs a paid search API key) | Claude (owner asked 11-20) | HIGH (Get-ChangeRisk said MEDIUM; HIGH used: CronJob + new Secret) | part A: "approve CR-2026-11-20-01 part A window now" (11-20 ~00:25, lapsed unpushed; re-approved same words 11-25) | part A 11-25 21:09-21:27 | part A done (Build #277); part B requested |
| CR-2026-11-19-06 | BT Hub (via BT Business support): port 80 -> IIS .101, remove stale LivBikoServer entries | Claude (after CR-19-02/-05) | HIGH | — | with BT, owner on the call | closed 11-19 - no change (HTTPS done under CR-19-02; port 80 + stale entries pending) |
| CR-2026-11-19-05 | EMERGENCY: public HTTPS outage 16:53-17:20 UTC caused by CR-2026-11-19-02 (Hub 443 rules removed, new rule refused); Hub restart; IIS-HTTPS rule added | Claude (during CR-19-02) | EMERGENCY | owner: "restart the Hub" (restart only) | 11-19 16:53-17:20 | done - restored |
| CR-2026-11-19-04 | IIS on BikoDC: Dynamic IP Restrictions (per-client rate + concurrent limits) on the public sites — only after CR-2026-11-19-02 | Claude (outage review 11-19) | HIGH (Get-ChangeRisk) | — | to propose after -02 | requested |
| CR-2026-11-19-03 | NDP uptime monitor every 2 min + all public hostnames (Tekeche, livbiko, 225woyo, kendebabi) | Claude (outage review 11-19) | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-19-03" 11-19 ~10:50 | 10:52-11:03 | done (NDP #276, a198758) |
| CR-2026-11-19-02 | BT Hub: public TCP 443/80 back to IIS BikoDC .101 (as before 11-14 07:30), dr-haproxy .50 out of the public path | Claude (outage review 11-19) | HIGH (Get-ChangeRisk) | — | 11-19: HTTPS 443 -> IIS .101 live 17:19 (port 80 still .50); caused outage CR-19-05 | partially done |
| CR-2026-11-19-01 | EMERGENCY: reset frozen dr-haproxy (all public sites down 06:11-07:35 and 07:41-~10:22) | Claude found it (uptime + checks), owner reset | EMERGENCY (Get-ChangeRisk said MEDIUM; HIGH by the rule) | owner reset it in their own ESXi session, "done" ~10:24 | — | done (service back ~10:22; Test-Build 8/8) |
| CR-2026-11-18-01 | NDP worker + API: channel statistics into channel_metrics, shown on cards; discovery topic map on active categories | Claude (follow-up of CR-2026-11-17-02/04) | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-18-01" 11-18 | 15:01-15:20 | done (NDP #269); first data run 11-19 08:25 (not 07:25: 20 h guard by seconds) verified: 915 rows, 305 channels x 3 metrics |
| CR-2026-11-17-04 | NDP worker: daily YouTube logos for every directory channel + statistics for channels with an account row (narrowed 11-18, owner option A) | owner (nested-categories brief 11-17) | HIGH (Get-ChangeRisk 11-18 on the narrowed change; was MEDIUM) | "approve CR-2026-11-17-04" 11-18; narrowed "A, write the CR" 11-18 | 11:07-11:28 ("approve CR-2026-11-17-04 window now" 11:0x) | done (NDP #266, worker b011f104) |
| CR-2026-11-17-03 | NDP /youtube nested pages: region / country / category / subcategory routes, breadcrumbs, nested menu, filters without reload | owner (nested-categories brief 11-17) | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-17-03" 11-18 | 12:30-14:14 | done (NDP #268, api 6ba17846, web 5eeae633) |
| CR-2026-11-17-02 | NDP migration 020: category hierarchy from the brief (8 categories, 70 subcategories), channel-category links, admin category management | owner (nested-categories brief 11-17) | HIGH (Get-ChangeRisk) | "approve CR-2026-11-17-02", "B", "approve CR-2026-11-17-02 window now" 11-18 | 11:38-12:28 (option B, whole) | done (NDP #267, api 6c75d01c, web 59622da6); CSV import pending owner review |
| CR-2026-11-17-01 | NDP API: stop fetching youtube.com/feeds/videos.xml (disallowed by YouTube robots.txt) | Claude (CR-11 finding) | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-17-01" ~00:55 | 01:03-01:40 | done (NDP #265, api 2f90a226) |
| CR-2026-11-16-11 | NDP /youtube redesign phase 1: new layout from existing data (web + read-only API) | owner (redesign brief 11-16) | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-16-11" ~17:50 | 17:55-20:53 | done (NDP #264, api 0b737600, web 296e4f87) |
| CR-2026-11-16-10 | OCI IAM policy + 30-day delete rule for bucket tekeche-mongo-backups | Claude (CR-09 follow-up) | HIGH (Get-ChangeRisk MEDIUM, raised: IAM = security) | — | proposed: now, 15 min | requested |
| CR-2026-11-16-09 | Tekeche MongoDB backups copied off-site to OCI Object Storage (replaces CR-08 step 2) | owner ("c, write the CR") | HIGH (Get-ChangeRisk) | "approve CR-2026-11-16-09 window now" ~16:57 | 16:58-17:26 | done (Build #66; lifecycle rule not set) |
| CR-2026-11-16-08 | Tekeche MongoDB backups: hourly, copied to BIKODC1, freshness check (option B) | owner ("B now, write the CR") | HIGH (Get-ChangeRisk) | "approve CR-2026-11-16-08 window now" ~16:45 | 16:46-17:11 | done (Build #65; step 2 -> CR-09) |
| CR-2026-11-16-07 | NDP: reject gambling candidates 144 and 524 (admin UI/API) | Claude | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-16-07" ~16:34 | 16:35-16:41 | done |
| CR-2026-11-16-06 | Tekeche New-RecoveryPoint: dump the production MongoDB (.53) and fail loudly | Claude | HIGH (Get-ChangeRisk) | "approve CR-2026-11-16-06" + "approve CR-2026-11-16-06 window now" ~16:28 | 16:28-16:33 | done (Build #64) |
| CR-2026-11-16-05 | NDP creator discovery: skip gambling/betting channels (worker build) | Claude | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-16-05" ~15:30 | 15:32-16:03 | done (worker a1952d25) |
| CR-2026-11-16-04 | Approve 3 Côte d'Ivoire creators (515-517) | owner decision ("Approve all 3") | HIGH (Get-ChangeRisk) | "approve CR-2026-11-16-04" ~13:33 | 13:35-13:45 | done |
| CR-2026-11-16-03 | Add 3 Côte d'Ivoire creator candidates (NDP admin API) | Claude (owner asked "go 3") | HIGH (Get-ChangeRisk) | "approve CR-2026-11-16-03" ~13:00 | 13:04-13:2x | done (creators 515-517, candidates) |
| CR-2026-11-16-02 | dr-haproxy: check for and delete leftover snapshot | Claude (owner asked) | HIGH | — | proposed: quiet hour, 20 min | requested |
| CR-2026-11-16-01 | Reset frozen dr-haproxy (all public sites down ~12:40-12:55) | owner / Claude | EMERGENCY (MEDIUM) | "logged in, reset it" 12:5x | — | done (service back 12:55; who reset it to be confirmed) |
| CR-2026-11-16-00 | Fraternité Matin feed time zone (label_time_zone Africa/Abidjan, 71 articles +2 h) | Claude | LOW | "approve 1" 12:1x | — | done 12:18 |

## Template

```
### CR-YYYY-MM-DD-NN  <title>
- Requested by:
- What changes (old -> new):
- Why:
- Class (Get-ChangeRisk):
- Impact / downtime:
- Rollback:
- Checks after:
- Window (HIGH):
- Approval (owner's words + time):
- Result:
```

### CR-2026-11-19-02  BT Hub: public 443/80 back to IIS on BikoDC; dr-haproxy out of the public path
- Requested by: Claude (root-cause review of CR-2026-11-19-01, owner asked for a permanent fix, 11-19).
- Evidence (IIS logs, all sites): until 11-14 07:30 the Hub forwarded straight to IIS .101 (real visitor IPs, months
  without a public-path freeze). From 11-14 07:30 traffic arrives from .50 only. 11-14: .50 from 07:30, NOTHING
  12:31-17:00 (unnoticed 4.5 h outage), direct to IIS again ~17:00-20:38, .50 again from 20:38, freeze 20:39. dr-haproxy
  froze 11-14, 11-16, 11-19 = every freeze since it entered the path; traffic flat (~110-115/min) up to the minute of
  each stop (no request flood). No change record, no Claude session and no UPnP mapping (no IGD answers) explains the
  11-14 switches. .50 is pure TCP passthrough (same certificates public / .50:8443 / IIS) - it adds nothing IIS lacks.
- What changes: BT Hub Manager > Advanced > Firewall > Port forwarding: TCP 443 -> 192.168.1.101:443 and TCP 80 ->
  192.168.1.101:80 (old: 443 -> .50:8443, 80 -> .50:8880). Record the full table before (screenshot + text). UDP
  443/500/4500 (VPN) untouched. dr-haproxy VM stays on (powered, unused) until the cause is known.
- Read-only first: Hub event log (who/when the 11-14 forwarding changes were made, admin logins), Hub remote-access
  setting, the full forwarding table.
- Why: removes the component that froze 3 times in 6 days; IIS sees real visitor IPs again (attack visibility,
  per-IP limits possible - CR-2026-11-19-04).
- Class: HIGH (Get-ChangeRisk). Window below.
- Impact: ~1-2 min of refused connections while the rule is saved (no Hub restart expected; if the Hub asks for a
  restart: stop, ~75 s outage, needs the owner's yes). IIS on .101 becomes the only box in the path (it already was
  for every request, behind .50).
- Rollback: put the two rules back to .50:8443 / .50:8880 (values recorded before).
- Checks after: from outside (WebFetch) nouvellesdupays.com, /api/countries, api.tekeche.com/health, tekeche.com,
  livbiko.com, 225woyo.com, kendebabi.com, security.tekeche.com; port 80 -> https redirect; IIS logs show public
  client IPs, none from .50; NDP Test-Build 8/8; uptime-state up.
- Window: 15 minutes, owner logged in to Hub Manager in the automated Chrome tab (Claude does not enter the Hub
  password). Proposal: as soon as the owner is available (quiet hours better: 03:00 UTC).
- Approval: needs "approve CR-2026-11-19-02 window <time/now>".
- 11-19 ~16:05 owner: "approve CR-2026-11-19-02 window now". Recovery points Tekeche 2026-11-19_16-07-38_before-cr-
  2026-11-19-02-bt-hub-443-80-ba, NDP 2026-11-19_16-07-40_... (+ on-prem pg dump 1.1G). Pre-check: IIS .101 answers all 7
  hostnames directly (https 200/302, http 301/200, certs to 2027). Hub (SH31B r5.19.3) event log only starts at the Hub
  restart 15/11 21:34 - the 11-14 changes cannot be traced. Table before: rule "LivBikoServer" = TCP 443->.50:8443 x2
  (device MAC 00:0c:29:f7:d8:4a), UDP 443->.101 x2 (user-defined IP), TCP/UDP 443->443 with NO device; rule
  "LivBikoServer80" = TCP 80->.50:8880 x2 (same MAC), TCP 80->80 with NO device. The old direct rules lost their device
  (likely how the 11-14 switch started). Hub deletes a rule BY NAME (all entries, applied at once) and a device edit
  duplicated rows/flagged invalid -> stopped unchanged, method went back to the owner.
- Revised method, owner 11-19: "approve CR-2026-11-19-02 revised method: delete and recreate LivBikoServer and
  LivBikoServer80 rules, test rule first, window now". 1) create + delete a test rule on a spare port to prove the
  create flow; 2) delete LivBikoServer + LivBikoServer80; 3) create LivBikoServer user-defined 192.168.1.101 TCP/UDP
  443->443 and LivBikoServer80 192.168.1.101 TCP 80->80. Outage ~2-3 min. Rollback: recreate both rules to .50:8443 /
  .50:8880 the same way.
- Result 11-19 (window, ~16:30-17:10 UTC): NOT DONE, stopped with the public path unchanged (all 7 hostnames + /health
  200/302 via 81.130.238.41, http 301). Saved changes: only test rule CRTEST TCP 18443 -> 192.168.1.101:443 (user-
  defined IP) - proven working (public :18443 -> IIS 200 in 0.1 s); it is STILL ON the Hub (same IIS sites on an extra
  port). Findings: deletes are pending until Save (good: one-Save swap possible), BUT the Hub editor is row-index based:
  "delete LivBikoServer" removed the wrong entry (dead TCP/UDP 443 entry became UDP) and deleting CRTEST moved CRTEST's
  IP onto the dead LivBikoServer row below it. Both pending sets discarded (Back, no Save). Device labels also flip
  between loads (Meraki-Webhooks shown as .105 then .214; .105 does not answer, .214 = MX). The device "BikoDC" (MAC
  02:bf:c0:a8:01:64) shows IP N/A - device-bound rules to it go nowhere. Likely 11-14 mechanism: the same row-shift
  when rules were edited. Next: owner decision (new Hub Manager Beta, owner-driven edit, or BT support/factory-style
  rebuild of the forwarding table); CRTEST to be removed in that same session.
- 11-19 second attempt (owner: "try the Beta Hub Manager", same approval). Beta: CRTEST deleted cleanly (live at once);
  deleted the 2 TCP 443 -> .50 entries ~16:52; Beta then refused every new 443 rule ("Duplicate external port range",
  even after deleting the 2 UDP 443 entries) and a delete failed (CHOP3-803). => PUBLIC OUTAGE ~16:53-17:20 UTC (all
  hostnames on 81.130.238.41: WAN 443 answered by the Hub itself, cert bthomehub.home). Misreads that cost time: LAN
  hairpin tests and the buffered IIS logs both looked "fine"/"down" wrongly; only outside fetches are truth. Hub restart
  ~17:06 (owner: "restart the Hub") did NOT help (classic view showed a stale table). Fix ~17:19 in classic view:
  deleted rule LivBikoServer (pending), added IIS-HTTPS TCP/UDP 443 -> 192.168.1.101:443, Save (CHOP3-803 shown, but
  IIS-HTTPS applied). Verified: outside fetch NDP / /api/countries (193) / livbiko / 225woyo OK, public client IPs
  connected straight to IIS, NDP Test-Build 8/8 17:20, uptime-state up 17:20:04 ("Sites back up" mailed).
- State now: 443 -> IIS .101 DIRECT (goal met for HTTPS). Port 80 still -> .50:8880 (http redirect only, still via
  dr-haproxy). Classic table still lists stale LivBikoServer entries (.50 TCP 443 x2, UDP 443 x2, device-less 443/80);
  their delete failed - which rule wins after a Hub reboot is UNKNOWN. No further Hub edits without the owner.
  Status: partially done (HTTPS) - incident CR-2026-11-19-05.

### CR-2026-11-25-06  NDP /youtube phase 2: languages (translation system, selector, detection, 9 languages)
- Requested by: owner 11-25 ("write the CR for YouTube phase 2"); brief section 1 (YouTube master prompt 11-25).
  Phase 3 (language URLs, hreflang/canonical per language, localised SEO titles in search results) stays separate.
- Facts (read 11-25): the whole site is French (<html lang="fr">, French text written inside ~15 files used by the
  /youtube pages: the 4 /youtube routes, YoutubeListing, CountryCreatorsView, DirectoryFilters, DirectoryCard,
  IndependentVoicesBanner, CountryExplorer, LatestVideos, VideoDirectory, LandingActions, LeadForm, LitePlayer,
  SiteFooter, not-found). Category names exist in the DB in French and English (creator_categories.name_fr/name_en);
  country names come from the browser/runtime (Intl.DisplayNames) for any language; an IP-country lookup already
  exists on the globe page (lib/geo.ts, ipapi.co from the browser). No new npm package is needed.
- What changes (part 2a - framework + French/English):
  1. Central dictionaries apps/web/src/i18n/{fr,en}.json + a t() helper (server and client); every user-facing
     string of the /youtube pages and of the shared components above moves there (French text unchanged).
  2. Language choice, in this order: (1) the visitor's saved choice (cookie ndp_lang, 1 year); (2) the browser's
     languages (Accept-Language on the server, so the first page is already right); (3) only when neither gives a
     supported language: the country (existing ipapi.co lookup in the browser, country->language table from the
     brief, e.g. CI/SN/ML->fr, NG/GH->en, MZ/AO/BR/PT->pt, KE->sw/en), saved as a suggestion; (4) French. No GPS
     prompt. Search engines (no cookie, usually no Accept-Language) get French = today's page.
  3. Selector "🌐 Français ▾" in the /youtube header: changing it sets the cookie and re-renders the same URL with
     the same query (country, category, search kept). Response header Vary: Cookie, Accept-Language.
  4. <html lang> (and dir) set from the chosen language on /youtube pages; dates and numbers formatted for it;
     country names per language (Intl.DisplayNames); category names from the DB (name_en for English).
  5. Channel descriptions and video titles stay as published (owner rule 11-16: only those stay untranslated).
- Part 2b (after 2a is live and checked): Portuguese, Spanish, Arabic (right-to-left: dir="rtl", layout audited for
  left/right spacing), German, Italian, Chinese, Swahili. DB migration 022 (additive): creator_categories.names
  jsonb {pt, es, ar, de, it, zh, sw}, filled once, editable later on /admin/categories; the API returns the name for
  the requested language, falling back to French. Rollback: column unused/dropped by the down script.
- Translation quality (said plainly): Claude writes the translations. They should be reviewed by a native speaker
  per language before being promoted; until then each non-French language is marked "beta" in the selector.
- Not in scope: other pages of the site (globe, /africa, /creators) - same framework can be extended later; Facebook
  and TikTok pages; machine translation of channel content.
- Tests: unit tests for the language choice (cookie > Accept-Language > country > French; unsupported codes),
  a test that every key exists in every dictionary; API test for category names per language (2b); browser checks:
  CI visitor (fr), NG/UK (en), manual switch keeps the filters, saved choice wins, Arabic page right-to-left (2b),
  phone + desktop; existing pages unchanged in French (screenshot diff of /youtube before/after in French).
- Deploy: push to main -> GitHub build 03:50 -> mirror 04:10 -> rollout 04:40 (or a manual run of the same chain);
  Test-Build NDP 8/8 + live checks; rollback = previous images (IDs saved) + git revert; 2b migration additive.
- Class: Get-ChangeRisk said LOW; MEDIUM used (migration in 2b, every /youtube page touched).
  Approval: "approve CR-2026-11-25-06 part 2a", later "approve CR-2026-11-25-06 part 2b".

### CR-2026-11-25-05  Temporary BikoDC firewall rule: TCP 3100 from the LAN, for the /youtube preview check
- Requested by: owner 11-25 ("try chrome extension again", "open port 3100"); for CR-2026-11-25-04's browser check.
- Why: the preview (new /youtube build on BikoDC :3100, test database with sample data) answers locally, but the
  owner's Chrome (Claude in Chrome) runs on another LAN machine and the Windows Firewall blocks inbound 3100 (checked:
  .51 -> 192.168.1.101:3100 times out). The BT Hub is NOT changed (that would expose the preview to the internet).
- What changes: New-NetFirewallRule "TEMP-CR-2026-11-25-05-preview-3100", inbound, TCP 3100, allow, remote address
  192.168.1.0/24 only. Nothing else is listening on 3100 (only the preview).
- Impact: the preview (sample data, no secrets, no admin) is reachable from the LAN for the test (~15 min).
- Test: from .51 -> 192.168.1.101:3100 answers 200; extension screenshots desktop 1366 + phone 390; expand/collapse,
  keyboard, country search, banner buttons.
- Rollback / end: Remove-NetFirewallRule -DisplayName "TEMP-CR-2026-11-25-05-preview-3100"; check from .51 that 3100
  times out again; stop the preview servers and remove the test database.
- Recovery point: Tekeche New-RecoveryPoint before (Get-ChangeRisk: MEDIUM). Test-Build Tekeche + NDP after.
- Class: MEDIUM. Approval: "approve CR-2026-11-25-05".
- Result 11-25 22:50-22:52: recovery point 2026-11-25_22-50-39; rule added; .51 -> :3100 200; Claude in Chrome loaded
  the preview at desktop width: banner next/pause work (wrap to start at the end), tree regions/countries open, links
  /youtube/cote-divoire[/news-media], search "nige" leaves only Nigeria, no horizontal overflow. Phone width could not
  be set in the extension window (stayed 1897 px) - phone layout was checked with headless Chromium at 390 px.
  Rule removed (verified absent; .51 -> :3100 times out again); preview servers stopped; test DB removed.
  Test-Build Tekeche 11/11, NDP 8/8.

### CR-2026-11-25-04  NDP /youtube redesign phase 1 (French): "Voix indépendantes africaines" banner + "Explorer par pays" tree
- Requested by: owner 11-25 (YouTube master brief, sections 2-6). Phases 2 (languages: central translation system,
  selector, detection saved > browser > country > French, 9 languages incl. Arabic right-to-left) and 3 (hreflang/SEO)
  get their own CRs.
- Found (read-only 11-25): /youtube already has tabs, a "Pays" section, nested pages /youtube/<pays>/<cat>/<sous-cat>,
  the category hierarchy + channel links in the DB (migration 020), flags from countries.flag_url, stored videos in
  channel_videos (filled daily by the YouTube API job), and GET /api/youtube/latest-videos (accepts the directory
  filters). The old banner "À la une · meilleur score africain" is a single top-ranked creator card.
- Banner data today (last 30 days, Africa): voix-locales 23 videos / 12 channels, media-en-ligne 2 / 1,
  voix-panafricaines 0, createur-independant 0 (their uploads are not collected), collectif 0. So the banner starts
  with ~25 videos from ~13 channels; fresh once a day (YouTube API quota), not live.
- What changes:
  1. API (read-only, no migration): latest-videos accepts several types at once (type=a,b,c) and returns each video's
     channel category; new GET /api/youtube/explorer = regions -> countries (ISO, French name, flag) -> categories ->
     subcategories with channel counts computed from the DB (cached like the directory). Countries with 0 channels
     shown greyed, not hidden counts.
  2. Web /youtube: the old featured card is removed; new banner "VOIX INDÉPENDANTES AFRICAINES" (subtitle as in the
     brief) = carousel of the latest videos of African voix-locales, voix-panafricaines, media-en-ligne,
     createur-independant and collectif channels: thumbnail, channel, flag, title, date, category, "Voir la vidéo",
     "Chaîne officielle"; latest first, max 2 per channel, no duplicates; previous/next buttons, pause, no auto-scroll
     when the visitor prefers reduced motion; "Mis à jour le ..." from the newest stored video; empty/error state.
     Refresh: page data revalidated every 15 min + the banner re-fetches every 15 min while open (configurable).
  3. "Explorer par pays": Afrique first (5 regions), then Europe, Asie, Moyen-Orient, Amérique du Nord, Amérique du
     Sud, Océanie - from the countries table (not hard-coded); expand region > country > category > subcategory, counts
     on each level, links to the existing /youtube/<pays>/<cat>/<sous-cat> pages (no new routes), current place
     highlighted, breadcrumbs, a country search box, keyboard + screen-reader accessible (button/aria-expanded).
     Desktop: sidebar next to the listings; mobile: a collapsible drawer.
  4. No new npm dependency; flags from the DB; everything in French (owner rule).
- Not in scope: languages (phase 2), new data collection for creators' videos (separate CR - would use YouTube quota),
  Facebook/TikTok pages (the explorer component is written to be reused).
- Tests: API tests for explorer counts (= DB counts) and multi-type latest-videos on the throwaway test DB; web
  typecheck + next build; browser check desktop + phone width (banner, explorer expand/collapse, keyboard, links);
  counts spot-checked against SQL for 3 countries; existing /youtube sections and country pages unchanged.
- Deploy: branch -> push to main in the window -> api + web image rebuild -> rollout -> Test-Build NDP 8/8.
  (Note CR-2026-11-25-03: a manual web build on .51 makes worker runs time out - deploy right after a worker run,
  or after CR-25-03 is done.)
- Rollback: previous api/web images (tags saved from the live imageIDs before deploy); git revert.
- Class: MEDIUM (Get-ChangeRisk). Approval: "approve CR-2026-11-25-04".
- Progress 11-25 22:18-22:45: NDP recovery point 2026-11-25_22-17-59 (dump 1.2G, live api/web imageIDs saved in
  live-images-before.txt). Built + committed NDP 90b4c99: API latest-videos multi-type + category + updated_at, new
  GET /api/youtube/explorer; web banner (IndependentVoicesBanner), tree (CountryExplorer + ExplorerShell), page wiring.
  Tests: API 176/176 (2 new: multi-type/latest fields; explorer counts = directory counts for every country,
  category and subcategory); tsc clean; next build OK; local check on the test DB (desktop 1366 + phone 390
  screenshots: banner, tree, no page overflow). A local check on production data was blocked (prod DB password on
  this host) - real-data check after deploy. Deploy plan: owner pushes NDP main -> nightly 04:10-04:40 rebuild +
  rollout (no daytime build on .51: it times out worker runs, CR-25-02 A) -> Claude runs Test-Build + live checks
  next session; rollback = previous imageIDs + git revert.

### CR-2026-11-25-03  Build the NDP images off .51 (GitHub Actions) + check the ESXi storage (replaces CR-25-02 part A)
- Requested by: owner 11-25 ("do it for me" = write the recommended next CR), after CR-2026-11-25-02 part A was rolled back.
- Why: measured 11-25 - the nightly web image build on .51 is disk-bound (npm ci + Kaniko filesystem snapshots). During
  one build: etcd fsync average 50 ms (24 ms otherwise), 22 fsyncs over 0.5 s, I/O pressure 75-90%, two worker runs
  timed out. The 11-18 worker failures (~04:20) and the 11-20 etcd freeze (04:23) fell in the same window. Throttling
  the build's CPU did not help. Other VMs are not an option: .52 is the NDP database, .52/.54 refuse Claude's key.
- What changes (Part 1, MEDIUM by Get-ChangeRisk, treated HIGH: new credential + deploy pipeline):
  1. NDP repo: .github/workflows/images.yml - on a schedule (03:50 UTC daily) and by hand (workflow_dispatch), build
     api, worker and web from main on GitHub's runners (same Dockerfiles, same build arg NEXT_PUBLIC_API_URL) and push
     to the PRIVATE GitHub Container Registry: ghcr.io/livbiko/nouvellesdupays-{api,web,worker}:main + :<commit sha>.
     Uses the workflow's own GITHUB_TOKEN (packages: write) - no secret added to the repo.
  2. On .51: the three Kaniko CronJobs dr-image-sync-{api,worker,web} are replaced by ONE light job
     dr-image-mirror (04:10): copies the three :main images from GHCR into the local registry 192.168.1.51:30500 as
     :local (crane copy - registry-to-registry, no npm, no build, no snapshots; a few hundred MB written). Everything
     else stays as is: every Deployment/CronJob keeps "192.168.1.51:30500/nouvellesdupays-*:local", dr-image-rollout
     04:40 unchanged, a push to main still goes live the next morning.
  3. Credential: a GitHub token that can only READ packages (owner creates it: fine-grained or classic read:packages),
     stored as a k8s Secret ghcr-read in the nouvellesdupays namespace, used only by dr-image-mirror. The owner pastes it
     into the command Claude gives (never in chat, never in git).
  4. Images stay private (not public: they contain the built app).
- Tests (Part 1): run the workflow by hand -> 3 images in GHCR with the commit sha; run dr-image-mirror by hand ->
  digests in the local registry = GHCR digests; measure etcd fsync + I/O pressure during the mirror (goal: no fsync
  over 0.5 s, no worker failure); restart api/web once (= normal rollout) -> Test-Build NDP 8/8, site checks.
  First night after: GitHub run 03:50 green, mirror 04:10 Complete, rollout 04:40 Complete, no worker failure
  04:00-05:00, etcd slow-apply count compared with earlier nights.
- Impact: GitHub Actions minutes (~10-15 min/day; private repos get a monthly free quota that depends on the plan -
  owner checks); GHCR storage (old :sha tags pruned to the last 10). Readers: nothing changes.
- Rollback: re-apply the saved Kaniko CronJobs (recovery point), delete dr-image-mirror + Secret ghcr-read, disable the
  workflow. The local :local images keep working throughout.
- Part 2 (HIGH, later, unchanged from CR-25-02 part B): ESXi storage check with the owner logged in; etcd on its own
  disk only if a faster datastore exists. Decided after Part 1's measurements.
- Approval: "approve CR-2026-11-25-03 part 1 window <time>" (owner also creates the read-only GitHub token).
- Part 1 result 11-25 22:57-23:28: recovery points 22-57-56 / 22-57-58 (dump 1.2G), Kaniko CronJobs saved. Repo is
  PUBLIC (Actions minutes free). Workflow images.yml pushed (NDP d95098e), run 45718492343: api 25 s, worker 23 s,
  web 61 s, prune OK. Token route failed 3x (owner script never reached .51 - sudo log empty); owner approved the
  revised method "public GHCR packages, no token" and made the 3 packages public. NOTE: Claude's first "private"
  check was wrong (its Accept header lacked the OCI manifest type, so it returned 404 either way) - the token may
  never have been needed. Applied CronJob dr-image-mirror (04:10, crane copy, Secret ghcr-read optional/unused); test
  run 23:22:56-23:23:40 (44 s): 3 digests local = GHCR; etcd during it 172 fsyncs, 0 over 0.5 s, 6 over 128 ms,
  +8 slow applies (Kaniko web build: 22 / 187 / +475 over 12.5 min). Suspended dr-image-sync-{api,worker,web}
  (kept). Worker 23:25 ran on the GHCR image a3e01cc9 - Complete, 872/883 feeds, 89 articles. Test-Build NDP 8/8.
  Set-KnownGood waits for the 04:40 rollout (api/web still old images) - with CR-2026-11-25-04's live check.
  Rollback: kubectl delete cronjob dr-image-mirror; patch dr-image-sync-{api,worker,web} suspend=false.
  Owner: delete the unused read:packages token on GitHub if one was created.

### CR-2026-11-25-02  etcd disk on dr-rke2 (.51): stop the nightly build from starving etcd; give etcd its own disk
- Requested by: owner 11-25 ("write the CR for item 1"), follow-up 1 of CR-2026-11-20-02.
- Facts measured 11-25 (read-only, .51 = 2 vCPU, 5.9 GB RAM, one 200 GB virtual disk "ROTA=1", etcd + containerd +
  Kaniko builds all on /dev/sda1):
  - etcd WAL fsync since boot (26 days, 1.72 M): only 11% under 8 ms, 56% under 16 ms, 77% under 32 ms; ~18,000
    over 128 ms and ~720 over 0.5 s; average 24 ms. etcd's guidance is p99 under 10 ms - this disk is ~10x too slow.
  - Backend commit average 49 ms; 32,049 "slow apply" events. Disk average write latency (diskstats) 41 ms.
  - Linux I/O pressure right now (no build running): "some" 16%, "full" 7-11% - the disk is busy all the time.
    Load average 3.4-3.9 on 2 vCPUs.
  - etcd database is small (11.7 MB, 7.5 MB in use): defragmenting would gain ~4 MB - NOT the fix.
  - Nightly builds: api 04:10 (~1 min), worker 04:15 (~1 min), web 04:20 (~10 min, Kaniko, CPU limit 1 of the
    node's 2, memory 2 Gi), rollout 04:40. The 11-20 freeze started 04:23:30 - during the web build. Kaniko image is
    "executor:latest" (not pinned).
  - Not yet known: the ESXi datastore type (SSD/HDD) under .51 and what else uses it (dr-haproxy .50 has a 69 GB
    snapshot, CR-2026-11-16-02, possibly on the same datastore).
- Part A (no downtime, MEDIUM): make the nightly web build gentler.
  1. dr-image-sync-web: CPU limit 1 -> 500m; Kaniko flags --snapshot-mode=redo and --compressed-caching=false
     (less disk and memory churn); pin the Kaniko image to the digest running today instead of :latest
     (same for the api/worker sync jobs).
  2. Spread the schedule so nothing overlaps the web build: web 04:20 -> 04:25 (api/worker done by then),
     rollout 04:40 -> 05:00 (web may now take ~15-20 min). The 04:10 rebuild rule stays (a push still goes live
     next morning, ~20 min later than now).
  3. Measure for 2 nights: etcd fsync histogram before/after 04:00-05:00 (metrics on 127.0.0.1:2381), build time,
     I/O pressure. Success = no fsync over 0.5 s during the build window and no slow-apply burst.
  - Impact: images ready later in the night; nothing changes for readers. Rollback: re-apply the saved CronJob YAMLs.
- Part B (HIGH, own window, after Part A data + an ESXi read-only check): a dedicated virtual disk for etcd.
  1. Owner opens the ESXi host client (logged in); Claude reads datastore type/free space and the other VMs on it.
  2. Add a 10-20 GB virtual disk to dr-rke2 on the fastest datastore available (SSD if any), format ext4, mount at
     /var/lib/rancher/rke2/server/db (fstab by UUID).
  3. Stop rke2-server (cluster API down; whether running pods keep serving is unproven - assume the sites go down
     for the ~10-15 min window), etcd snapshot (`rke2 etcd-snapshot save`) + copy of db/, copy the data onto the new
     disk, start rke2-server, check node Ready, etcd health, fsync histogram.
  - Rollback: stop rke2, unmount the new disk (old db/ kept untouched underneath), start rke2; or restore the
    snapshot (`rke2 server --cluster-reset --cluster-reset-restore-path=...`).
  - If the ESXi check shows only one slow datastore, a new disk on it will not help: Part B then becomes "move .51
    to faster storage / reduce what shares it" and comes back to the owner as a revised CR.
- Not in scope: the etcd watchdog (follow-up 2), the third-place uptime check (follow-up 3), the dr-haproxy
  snapshot (CR-2026-11-16-02).
- Recovery points: Tekeche + NDP before each part; save the 4 sync/rollout CronJob YAMLs.
- Tests after: Test-Build NDP 8/8 (+ Tekeche 11/11); next morning: all 3 builds Complete, rollout done, images
  fresh, site up; etcd metrics compared.
- Class: Get-ChangeRisk said MEDIUM. Part A: MEDIUM -> approval "approve CR-2026-11-25-02 part A".
  Part B: HIGH (etcd data move, cluster stop) -> "approve CR-2026-11-25-02 part B window <time>".
- Part A result 11-25 21:41-22:03: recovery points 21-41-19 / 21-41-21 (dump 1.2G); applied the 4 build CronJobs
  (kaniko pinned sha256:4e7a52dd..., web 500m CPU + --snapshot-mode=redo + --compressed-caching=false, web 04:25,
  rollout 05:00; repo had a stale rollout image bitnami/kubectl:1.31 - aligned to live registry.k8s.io/kubectl:v1.35.7).
  Test: one web build 21:47:13-21:59:47 (Complete, 12.5 min). During it: 2,584 etcd fsyncs, average 50 ms (lifetime
  24 ms), 187 over 128 ms, 22 over 0.5 s, +475 slow applies, I/O pressure 75-90%. Success goal (no fsync over 0.5 s)
  NOT met. Worker runs 21:50 and 21:55 failed (DeadlineExceeded) during the build -> Test-Build 7/8 -> ROLLED BACK
  at 22:01 (saved CronJob YAML re-applied, verified: old schedules, :latest, CPU 1, original args); worker 22:00 run
  Complete; Test-Build 8/8 at 22:02. Repo reverted (1fef0eb), rollout image alignment kept.
  Finding: the 11-18 worker failures (~04:20 UTC) also fell in the nightly web build - the build starves .51
  whatever its CPU limit (it is disk-bound: npm ci + kaniko filesystem snapshots). Better fix than throttling: build
  the images somewhere else (not on .51), and/or Part B (etcd on its own, faster disk). Needs a revised CR.

### CR-2026-11-25-01  Uptime check outside the on-prem cluster (BikoDC scheduled task)
- Requested by: Claude, follow-up 1 of CR-2026-11-20-02 (owner "go next" 11-25).
- Why: 11-20 the sites were down 9 h with no alert - the only uptime check (CronJob nouvellesdupays-uptime) runs
  inside the RKE2 cluster on .51 that had failed.
- What changes:
  1. New script tekeche/ops/scripts/Watch-PublicUptime.ps1 (in git): every run checks https://<host>/ for
     nouvellesdupays.com, tekeche.com, api.tekeche.com/health, livbiko.com, 225woyo.com, kendebabi.com and
     nouvellesdupays.com/api/countries through the public IP 81.130.238.41 (curl --resolve, full TLS check, 15 s
     timeout; 2xx/3xx = up). Same rule as the cluster check: DOWN mail after 2 failed runs in a row (~4 min), one
     UP mail on recovery, listing which hosts failed and the error. State in C:/ops/uptime-outside/state.json.
  2. Mail via the Brevo API, sender noreply@nouvellesdupays.com (already authenticated), to the owner's address
     (same as the cluster check). The NDP Brevo key is copied from the cluster secret into a DPAPI-encrypted file
     (LocalMachine scope, ACL SYSTEM + Administrators) - never in git, never printed.
  3. Scheduled task "NDP-Uptime-Outside" on BikoDC, SYSTEM, every 2 min, 60 s limit, no overlap.
  4. One test mail (subject "[TEST] uptime-outside") to prove delivery, then normal mode.
- Impact: ~4,300 small HTTPS requests/day through the Hub to IIS (same as the cluster check); no change to any site,
  the Hub, IIS or the cluster. Two DOWN mails if both checks see an outage - intended.
- Limits (said plainly): it runs on BikoDC, which also hosts IIS - if BikoDC itself or the internet line is down,
  it cannot send. A check from a third place (OCI or an external monitor) would close that; separate CR.
- Tests: run the script once by hand (all up -> no mail, state written); simulate a failure with a test host list
  pointing at an unused port (DOWN after 2 runs, then UP) using a separate test state file; test mail received.
- Recovery point: Tekeche New-RecoveryPoint before starting. Test-Build (Tekeche + NDP) after.
- Rollback: Unregister-ScheduledTask NDP-Uptime-Outside; delete C:/ops/uptime-outside; revert the script commit.
- Class: MEDIUM. Approval: "approve CR-2026-11-25-01".
- Result 11-25 21:32-21:36: recovery point 2026-11-25_21-32-41; script committed; Brevo key copied from the cluster
  secret into C:/ops/uptime-outside/brevo.key (DPAPI LocalMachine, ACL SYSTEM:R + Administrators:F, never printed).
  Tests: normal run all up (no mail); simulated outage on a test state file -> no mail after run 1, DOWN after run 2,
  UP on recovery; [TEST] mail; [SYSTEM] test mail from a SYSTEM task (removed after). Task NDP-Uptime-Outside
  (SYSTEM, every 2 min) first run result 0, state up. Deviation: task time limit 5 min (not 60 s) + IgnoreNew,
  because 7 checks timing out take ~105 s. Test-Build Tekeche 11/11, NDP 8/8. Owner: confirm the 4 test mails
  ([TEST] DOWN, [TEST] UP, [TEST] mail delivery, [SYSTEM][TEST]) arrived.

### CR-2026-11-20-02  EMERGENCY: etcd hung on dr-rke2 (.51) - sites down 04:24-13:18 UTC
- Symptom: IIS (W3SVC9) answered 502 for nouvellesdupays.com from 04:24:18 to 13:15:31 (short recovery 10:56-10:59);
  from outside at 13:08 NDP and 225woyo.com timed out, tekeche/livbiko/kendebabi were up. Hub/IIS path fine
  (external connections on IIS :443, certs valid).
- Cause found: on .51 the etcd process (pid 1417, up 20 days) stopped answering (/health timed out, its log
  ends 04:23:30, already "apply request took too long" 100-300 ms just before). From 11:02 rke2-server crash-looped
  (530 failed starts: "failed to reconcile with local datastore: context deadline exceeded"), kube-apiserver timed
  out. 04:23 = the daily image rebuild window (Kaniko builds 04:10-04:20 on the same disk; dr-image-sync-web was
  stuck "Unknown" for 9 h). Why the running web/api pods stopped serving while the API was down is NOT proven.
- Not an attack: no request flood; the failure is inside the cluster's database.
- Action (minimum): copied etcd member dir to /home/ubuntu/etcd-backup-2026-11-20T1314 (376 MB); SIGTERM, then
  SIGKILL etcd (did not stop in 20 s); systemctl restart rke2-server -> active 13:18:41, node Ready, etcd new pid.
  Missed CronJobs then ran (incl. dr-image-rollout: new api/web pods 13:20).
- Checks: 13:19 + 13:21 all 6 hostnames 200 via 81.130.238.41 with full cert checks; /api/countries 200; outside
  WebFetch nouvellesdupays.com + 225woyo.com load; uptime-state "up".
- Gap: the uptime CronJob runs INSIDE this cluster, so it could not run and sent no DOWN email for 9 h.
- Follow-ups (need CRs): (1) uptime check from outside the cluster (e.g. a Windows task on BikoDC or OCI);
  (2) etcd/disk: defrag + check latency of the .51 datastore, move the 04:10 Kaniko builds off etcd's disk or
  space them out; (3) an etcd/apiserver health watchdog on .51; (4) find why pods stopped serving.
- CR-2026-11-20-01 part A (discovery) was not involved: its code is committed locally only, nothing applied.

### CR-2026-11-20-01  NDP discovery: all regions + priority countries + search-API discovery
- Requested by: owner 11-20 ("write the CR for items 1 and 2" of the discovery-brief status).
- Why (measured in prod 11-20): 193/193 countries have an active publisher, but 18 have fewer than 3 and 8 have
  only 1 (Mongolia, Vatican City, Trinidad and Tobago, Micronesia, Palau, Nauru, Kiribati, Tuvalu); Tuvalu has no
  article in 7 days. The hourly job nouvellesdupays-discovery only mines homepages of AFRICAN publishers for outbound
  links (DISCOVERY_REGION = the 5 African regions, MINE_LIMIT 6, CHECK_LIMIT 40); its last run found 0 new
  candidates. Countries outside Africa get no automatic discovery at all.
- What changes - Part A (no new key, code + CronJobs):
  1. apps/worker/src/discover.js: DISCOVERY_REGION accepts "all" (every countries.region); new
     DISCOVERY_PRIORITY_MAX_ACTIVE (default 2) = mine/check only countries with <= N active publishers, re-computed
     every run from prod data (no fixed list).
  2. CronJob nouvellesdupays-discovery (hourly): DISCOVERY_REGION -> all. Limits unchanged (6 homepages mined,
     40 candidates checked per run).
  3. New CronJob nouvellesdupays-discovery-priority, every 6 h (minute 47, not 17, so the two never overlap;
     concurrencyPolicy Forbid, activeDeadline 1500 s, backoffLimit 0): same image, priority mode.
- What changes - Part B (only after the owner has chosen and paid for a search API and created the key):
  4. New search step in discover.js: per priority country, queries built from the country registry (name in its
     official languages + "news"/"actualites"/"noticias"/... and the capital), results -> the SAME candidate
     pipeline (dedupe by domain against publishers/submissions/candidates, robots.txt, feed/sitemap test, spam
     check) with discovery_method='search' and the query stored. Nothing is auto-approved: candidates land in
     /admin/discovery for the owner as today.
  5. Budget: DISCOVERY_SEARCH_BUDGET_PER_RUN (default 30 queries) + monthly cap DISCOVERY_SEARCH_BUDGET_MONTH
     (default 3000), counted in a new table discovery_search_log (migration, additive, reversible); the step stops
     when either is reached. Key in a new Secret ndp-search-api (never in git, never printed).
  - Provider: owner's choice. Must be an official search API whose terms allow this use (no scraping of search
    result pages). Candidate: Brave Search API. Bing Web Search API is retired. Price/quota: owner checks at sign-up.
- Not in scope: TikTok/Facebook discovery (no permitted API), auto-approval, the admin dashboard, the 4 scores.
- Impact: new crawl load = robots.txt + homepage + feed tests for up to 40 candidates per run (bot UA, robots
  respected, as today), plus the 6-hourly run. DB: inserts into discovered_sources only (+ discovery_search_log in
  B). No change to publishers, articles, the public site or the ingest worker. Search cost (B) capped by budget.
  Review load for the owner grows (more candidates in /admin/discovery).
- Tests before deploy: discover.test.js fixtures (fetch mocked): "all" regions, priority filter (<= N active),
  search step dedupe/budget stop/no-key = skipped (B), existing tests still pass; dry run against prod data
  (read-only, DISCOVERY_DRY_RUN) listing what would be mined/checked.
- Deploy: branch -> owner pushes to main (daily 04:10 rebuild makes main live; push only in the window) -> image
  rebuild (Kaniko, one at a time) -> apply CronJobs -> trigger one manual run of each -> NDP Test-Build 8/8.
- Checks after: both CronJobs listed with the right schedules; first runs Complete, logs show countries outside
  Africa mined; new discovered_sources rows have country + method; no errors in worker/api; site pages unchanged;
  uptime up. Part B: discovery_search_log counts <= budget; candidates carry discovery_method='search'.
- Recovery point: Tekeche + NDP New-RecoveryPoint before starting; save current CronJob YAML.
- Rollback: re-apply the saved nouvellesdupays-discovery CronJob (5 African regions); delete CronJob
  nouvellesdupays-discovery-priority; previous image tag; Part B: delete Secret ndp-search-api, migration down drops
  discovery_search_log. Candidates already found stay as review items (owner can reject; nothing deleted).
- Class: HIGH (CronJob change + new Secret; Get-ChangeRisk said MEDIUM, higher class used). Duration ~45 min per
  part. Approval: "approve CR-2026-11-20-01 part A window <time>" and, later, "approve CR-2026-11-20-01 part B
  window <time>" (after the key exists).
- Part A result 11-25 (window 21:09-21:27, owner re-approved; owner "do it for me" -> Claude pushed 5a5cfad, ls-remote
  verified): recovery points 2026-11-25_21-09-02 / 21-09-04 (dump 1.2G); worker image rebuilt from main
  sha256:f4ab48e1..., change checked inside the image + dry run (18 priority countries); applied ONLY the two CronJobs
  (discovery -> "all", new discovery-priority 47 */6); one manual run each: discovery mined 6 (BBC, Guardian,
  Independent, Mirror, Le Monde, Le Figaro) -> 36 new candidates, checked 37 (20 ok, 11 not_news, 4 unreachable,
  1 spam_suspect, 1 robots); priority mined 6 -> 1 new, checked 1. Test-Build 8/8, Set-KnownGood Build #277.
  Rollback if needed: re-apply cronjob-nouvellesdupays-discovery.before.yaml from the NDP recovery point, delete
  CronJob nouvellesdupays-discovery-priority, previous worker image from worker-image-before.txt (11-20 point).

### CR-2026-11-19-06  BT Hub: port 80 to IIS .101 + remove stale LivBikoServer entries (via BT Business support)
- Requested by: Claude after CR-19-02/-05 (owner "go-ahead" 11-19 - not an approval; this CR records the plan).
- Why: port 80 still goes to dr-haproxy (.50:8880, http->https redirect only); the Hub table still lists stale
  LivBikoServer entries (TCP 443 -> .50:8443 x2, UDP 443 -> .101 x2, device-less 443 and 80) whose delete fails
  (CHOP3-803) - after a Hub reboot the wrong rule could win again. The Hub UIs proved unsafe for this (CR-19-05).
- What changes (BT does it, owner on the call): remove all "LivBikoServer" and "LivBikoServer80" entries; keep
  IIS-HTTPS (TCP/UDP 443 -> 192.168.1.101:443); add IIS-HTTP TCP 80 -> 192.168.1.101:80; all other rules (VPN UDP
  500/4500, Meraki .214, CWPHost .113) untouched. Ask BT why the rule store and the running rules disagree.
- Pre-check (done 11-19): IIS .101 answers http on 80 for all hostnames (301, livbiko 200).
- Impact: HTTP redirect may blip ~1 min; HTTPS unaffected if BT does not touch IIS-HTTPS; a Hub reboot = ~2 min
  office-wide drop.
- Checks after: from OUTSIDE (WebFetch) all hostnames https + http->https; cert subject on 81.130.238.41 is the site
  cert (not bthomehub.home); Get-NetTCPConnection :443/:80 shows public IPs on .101; NDP Test-Build 8/8; uptime up.
- Rollback: BT re-adds TCP 80 -> 192.168.1.50:8880.
- Class: HIGH (Hub, public path). Approval: "approve CR-2026-11-19-06 window <time>" (owner on the BT call).
- Result 11-19: window approved ~17:28 (recovery points 17-28-35/17-28-37). BT made no change (table read-only
  checked: IIS-HTTP absent, LivBikoServer80 -> .50:8880 still present). Owner did not approve the revised method
  (Claude edits the Hub). Owner: "close CR-06". CLOSED, no change made. State at close (checked from here with full
  cert checks, 81.130.238.41): nouvellesdupays.com + tekeche.com https 200 (direct to IIS .101, rule IIS-HTTPS);
  http 301 -> https still via dr-haproxy .50:8880. Still open: port 80 off .50 and the stale LivBikoServer entries.
  Needs a new CR (BT or owner-approved Hub edit).

### CR-2026-11-19-03  Uptime monitor every 2 minutes, all public hostnames
- Requested by: Claude (outage review 11-19).
- What changes: CronJob nouvellesdupays-uptime schedule */10 -> */2; uptime.sh checks also api.tekeche.com/health,
  tekeche.com, livbiko.com, 225woyo.com, kendebabi.com (the failed names in the email); FAIL_THRESHOLD stays 2 (DOWN
  email after ~4 min instead of ~20). ConfigMap uptime-script + CronJob only; same Brevo key, same recipient.
- Why: 11-19 the 06:11 outage was mailed ~06:30; a bypass of .50 or a reset could start 15 min earlier. Tekeche
  hostnames are not checked at all today.
- Class: MEDIUM (Get-ChangeRisk). Impact: ~720 small requests a day through the public path; no downtime.
- Rollback: re-apply the saved CronJob/ConfigMap (kept in the recovery point).
- Checks after: one run OK with no email; a forced-failure run on uptime-state-test (threshold 1) sends one DOWN email
  (as Build #252); Test-Build 8/8.
- Approval: "approve CR-2026-11-19-03" (owner, 11-19 ~10:50).
- Result: recovery point 2026-11-19_10-52-52; test run 7/7 OK no mail; forced failure -> one DOWN mail "[NDP] Site
  DOWN: forced-test", test state reset by hand; live uptime-script = repo (sha256), CronJob */2, deadline 110 s;
  scheduled runs 11:00/11:02 7/7 OK; Test-Build 8/8; NDP known-good #276 (a198758). Done.

### CR-2026-11-19-04  IIS Dynamic IP Restrictions on the public sites
- Requested by: Claude (outage review 11-19; owner asked for controls against attacks).
- Depends on CR-2026-11-19-02 (with .50 in the path every visitor is 192.168.1.50 and a per-IP limit would block
  everyone).
- What changes: install the IIS "IP and Domain Restrictions" feature if missing; per public site: deny by concurrent
  requests (> 40 from one IP) and by request rate (> 300 per 10 s from one IP), deny action 403; exempt LAN
  192.168.1.0/24 and the OCI range 10.0.0.0/16. Logging-only mode first for 24 h (Dynamic IP Restrictions logging
  only), then enforce after reading the log.
- Class: HIGH (Get-ChangeRisk). Rollback: disable the two settings per site (applicationHost.config backup in the
  recovery point).
- Checks after: normal browsing, NDP Test-Build, Tekeche Test-Build, a 400-request burst from one outside IP gets 403.

### CR-2026-11-19-01  EMERGENCY: reset frozen dr-haproxy (third freeze in 6 days)
- Requested by: Claude found it 11-19 ~08:31 while checking CR-2026-11-18-08; the owner did the reset.
- What changed: ESXi Reset of VM dr-haproxy (vms/70, 192.168.1.50). Nothing else.
- Correction (11-19 ~11:00, IIS logs): the outage began at 06:11:29, not 07:50 (normal ~110 req/min until 06:11, then
  nothing); .50 passed traffic again 07:35-07:40 (uptime run 07:40 OK) and stopped again ~07:41. The uptime job mailed
  DOWN ~06:30, UP 07:40, DOWN ~08:00, UP 10:30. Total ~4 h down.
- Why / evidence: uptime-state down since 07:50:03 UTC (homepage + api, every 10-min run, 16 fails to 10:20);
  .50 answered ping but TCP 80/443 timed out; ingress .51 (200 in 0.02 s) and IIS .101 answered; api.tekeche.com via
  .50 failed too. Same signs as 11-14 / 11-16 (CR-2026-11-16-01).
- Class: Get-ChangeRisk said MEDIUM; treated as HIGH (public entry point) and done as EMERGENCY (section 5). The
  automated ESXi tab was logged out (inactivity), Claude does not enter ESXi passwords: owner reset it themselves.
- Impact: NouvellesDuPays, Tekeche (api.tekeche.com, tekeche.com), livbiko.com, 225woyo.com, kendebabi.com
  unreachable from outside ~07:50 to ~10:22 UTC (~2.5 h). Down email sent by the uptime job at the state change.
- Rollback: none (a reset).
- Checks after (10:25-10:27): via the public IP: nouvellesdupays.com / and /api/countries 200, api.tekeche.com/health
  200, tekeche.com 200, livbiko.com 200, 225woyo.com 200, kendebabi.com 200, security.tekeche.com 302; NDP Test-Build
  8/8. uptime-state to flip "up" at the 10:30 run (recovery email).
- Follow-up (normal process): CR-2026-11-16-02 (leftover snapshot, main suspect) still "requested" — its read-only
  step 1 needs the owner logged in to ESXi; deleting needs "approve CR-2026-11-16-02 window <time>".

### CR-2026-11-18-08  NDP: "Dernières vidéos" — latest uploads of the directory channels, daily, official API
- Requested by: owner ("2, write the CR", 11-18 ~23:45) after asking why /youtube videos date from 02-03/10.
- Found: "Vidéos sélectionnées" = youtube_videos, 42 hand-picked videos all added 10-02/10-03 (40 approved), nothing
  added since; 41 of 42 have no published_at, the page shows the add date. No automatic source (feeds/videos.xml is
  disallowed by youtube.com/robots.txt, stopped in CR-2026-11-17-01).
- What changes:
  1. Migration `021_channel_videos.sql` (new table only, nothing existing altered): channel_videos (youtube_video_id PK,
     channel_key, title, published_at, thumbnail_url, fetched_at); index (published_at DESC), (channel_key).
  2. Worker `channel-logos.js` daily step (same 20 h guard, same 'youtube' agent budget in agent_runs): after
     channels.list, for each returned channel one `playlistItems.list` on its uploads playlist (part snippet,
     contentDetails, maxResults 5; 1 unit each) -> upsert the 5 latest uploads. Videos older than 30 days and rows not
     refreshed for 30 days are deleted (YouTube API data is not kept stale). Only titles, ids, dates and thumbnails
     on i.ytimg.com are stored; nothing is downloaded or hosted. Stops cleanly when the budget is used.
     Quota: ~305 units/day more (today 7/day for logos; agent 3,192 in the last 24 h; budget 8,000).
  3. API `GET /api/youtube/latest-videos?limit=&country=&category=`: newest first, at most 2 per channel, only
     channels shown in the directory; cached like the directory.
  4. Web: a "Dernières vidéos" section on /youtube (24 videos: thumbnail, title, channel, country, "il y a 3 h"
     from published_at, link to YouTube — no embed); the hand-picked "Vidéos sélectionnées" section stays below it.
     All text in French.
  Tests: worker (fake API: upsert, 30-day purge, budget stop), API (ordering, 2 per channel, filters), web build.
- Class: HIGH (Get-ChangeRisk 11-18: database migration + quota + new feature). Window below.
- Risks: quota ~305 units/day added to the shared YouTube budget (discovery gets less); the first run waits for the
  20 h guard (next logo run 11-19 07:25) unless one run is started by hand in the window; a channel's uploads
  playlist may be missing or private (counted, skipped).
- Rollback: worker / API / web rollback tags from the live imageIDs; table left in place but unused, or dropped with
  reverse.sql (`DROP TABLE channel_videos` — rehearsed); migration file guarded so re-runs are no-ops.
- Checks after: migration rehearsed (BEGIN..ROLLBACK) then applied; one run: units used = channels + ~7, rows ~5 x
  channels returned, 3 sampled videos match YouTube (title, date); /youtube shows "Dernières vidéos" with dates
  from today/yesterday; 390 px no overflow; tests; Test-Build 8/8.
- Window: proposal 11-19 after the channel-metrics check (~08:00 UTC, 60-90 minutes incl. build + one manual run),
  or a time you name. Code and tests can be written before the window but NOT pushed (a push goes live at 04:10).
- Approval: "approve CR-2026-11-18-08" (11-18 ~23:50), "approve CR-2026-11-18-08 window now" (11-19 ~00:05).
- Result: deployed 00:15-00:50 11-19, NDP known-good #275 (ce68f66 + 199e264). Migration 021 rehearsed then applied;
  api 3e4d51f1, web 16cb4105, worker 6672e084; rollback tags api 22a18527 / web e4efe04c / worker 00116118; recovery
  point 2026-11-19_00-08-33_before-cr-2026-11-18-08-ndp-latest-video + DB dump ndp-daily-2026-11-19.dump. Tests API
  174/174, worker 124/124; worker runs 00:40/00:45 OK; pages 200; Test-Build 8/8. Deviation from the CR: no manual
  uploads run (the 20 h guard; forcing it would fake the quota bookkeeping) — first videos with the 07:25 run, to
  check then. Added in the window: tab hidden while the section is empty (199e264).
  First run 11-19 08:25 (07:25 skipped: guard counts from 11-18 11:25:18, job started seconds before): 1,302 videos
  from 274 channels (298 returned, 7 playlist 404 skipped), 0 purged, quota 312 units, run 4 m 50 s; API 12 items
  max 2/channel 0.66 s; /youtube shows section + tab, "il y a ..." dates (checked at the ingress during the
  dr-haproxy outage, CR-2026-11-19-01). 3 videos vs YouTube: pending.

### CR-2026-11-18-07  NDP data: import the channel classification (237 rows)
- Requested by: owner ("do it for me" -> Claude filled the decisions, "run Vérifier", "write the CR", 11-18 ~23:30).
- What changes: one import on /admin/categories ("Appliquer") of
  `ops/release-category-hierarchy/classification-claude-recommendations.csv` = the review file with owner_decision
  filled BY CLAUDE: "ok" (accept the proposal) on the 237 high/medium-confidence rows, empty (skipped) on the 100
  low-confidence rows. Through the admin API only (no SQL writes).
  - 212 directory channels get their categories (video_channel_category_links is empty today): primaries
    national-news 130, tv-radio 64, international-affairs 9, business-news 9, politics 8, others 1-5 each.
  - 25 approved creators: their categories are REPLACED by the proposal (creator_category_links rows of those 25).
- Dry run ("Vérifier", 23:20 UTC, owner's admin session): 337 rows, 237 to apply, 100 skipped, 0 errors.
- Why: subcategory pages on /youtube stay empty until channels are classified (CR-2026-11-17-02/-03).
- Class: HIGH (Get-ChangeRisk 11-18: production data, 237 rows). Window below.
- Impact: /youtube category and subcategory pages and filters change at once (directory cache cleared by the import);
  sitemap gains the newly non-empty pages. No downtime.
- Rollback (the import cannot undo itself: the export has no creators and an empty row is skipped): before the import,
  a data snapshot of video_channel_category_links (0 rows) and of creator_category_links for the 25 approved creators
  into the recovery point, and `reverse.sql` = delete all video_channel_category_links + put back those 25 creators'
  old links; rehearsed (BEGIN ... ROLLBACK) before the window. Recovery point + DB dump.
- Checks after: admin "Classement des chaînes" shows 212 classified; /youtube/categorie/news-media/national-news and
  a sample of subcategory pages 200 with channels; sitemap URL count before/after; 20 random channels' categories =
  the file; the 25 creators' public pages 200 with the new categories; Test-Build 8/8.
- Open questions for the owner before approving: (1) the 25 creator rows replace categories you may have set by hand
  — keep them in, or set those rows to empty to leave creators as they are? (2) culture-society, journalism and
  technology-it were edited 14:56-14:58 UTC today (journalism and culture-society switched back on) — yours?
- Window: proposal now, 20 minutes, owner logged in to /admin.
- Approval: "approve CR-2026-11-18-07", "approve CR-2026-11-18-07 window now" (owner, 11-18 ~23:27); then owner chose
  "Leave them as they are" for the 25 creators.
- Result: APPLIED BY THE OWNER, NOT THROUGH THE PLANNED STEPS. The owner clicked "Appliquer" at 23:26:11 in the admin
  tab where Claude had run "Vérifier" (23:23:13) with the full 237-row file — before the window approval, the
  recovery point (23:28) and the before-snapshot; confirmed by the owner ("yes"). Written 23:26:12: 320 channel links
  for 212 channels (212 primary) and the 25 approved creators' categories REPLACED (creator_category_links 1,435 ->
  1,461), although the owner's later answer was to leave creators unchanged. No before-snapshot of those 25 creators'
  links. Checks: sitemap /youtube 566 -> 1,067 URLs (501 new, 0 gone), 30 new pages 200 with channels, category
  pages 200, 25 creator pages 200, unknown 404, Test-Build 8/8. Undo for channels: cr1807-reverse.sql (rehearsed);
  creators: only from a dump taken before 23:26 — owner decision pending (keep / restore creators / undo all).

### CR-2026-11-18-06  NDP worker: one bad feed must not crash the whole poll run (NUL bytes)
- Requested by: Claude, from a read-only look at the failed worker pods (owner "keep going", 11-18 ~22:35).
- Found: worker runs 09:40, 09:45 and 09:50 UTC on 11-18 failed (2 attempts each, 6 pods in Error):
  `invalid byte sequence for encoding "UTF8": 0x00` thrown by the error handler of `pollFeed` (poll.js:424) — a feed's
  error message contained a NUL byte, writing it to feeds.last_status / last_error failed, and that second error was
  not caught, so Promise.all rejected and no feed was polled or recorded in those 3 runs. It stopped by itself at
  09:55; which feed is not in the logs (the run died before printing it).
- What changes (worker `poll.js` only):
  1. Strip `\u0000` from the error message before it is logged or stored.
  2. The error-recording UPDATE in the catch block gets its own try/catch (logs and carries on).
  3. Strip `\u0000` from the text fields of new article rows (headline, summary, author, category) before INSERT,
     so a feed with a NUL in its content is stored instead of failing every run.
  Tests: a fake feed whose error message has a NUL, and one with a NUL in a headline; the run completes for the
  other feeds.
- Class: MEDIUM (Get-ChangeRisk 11-18, run alone).
- Impact / downtime: none (worker CronJob pulls :local on the next run after the build).
- Rollback: worker rollback tag from the live imageID.
- Checks after: worker tests; next 3 runs succeed; feeds ok count normal; Test-Build 8/8.
- Approval: "approve CR-2026-11-18-06" (owner, 11-18 ~22:37 UTC).
- Result: deployed 22:46 (worker 00116118), NDP known-good #274 (b437e9e), rollback-25d4ed8b; recovery point
  2026-11-18_22-38-49_before-cr-2026-11-18-06-ndp-worker-nul-b. Worker tests 122/122 (3 new). Runs 22:50, 22:55,
  23:00 all succeeded (ok 468-498, errors 13-15, 0 record failures); Test-Build 8/8.

### CR-2026-11-18-05  NDP: page rendering no longer shares one API rate limit (web -> API inside the cluster)
- Requested by: Claude, from the read-only investigation of the 20:56 burst (owner "keep going", 11-18).
- Found (11-18 21:35-21:45 UTC, read-only):
  1. Public traffic enters through IIS ARR on the ops host (site nouvellesdupays.com,
     C:\inetpub\wwwroot\proxy-nouvellesdupays, rewrite to http://192.168.1.51). The ingress sees the client as
     192.168.1.101 (3,058 of 3,119 requests 20:55-21:05, incl. GPTBot and OAI-SearchBot); its config has no
     use-forwarded-headers, so the API (trustProxy, rate limit 100/min per IP) counts every visitor as one IP.
  2. The on-prem web deployment has no API_INTERNAL_URL (the OKE manifest 07-web.yaml had it), so server-side
     rendering calls https://nouvellesdupays.com (baked NEXT_PUBLIC_API_URL) and goes out and back through the BT
     Hub and ARR: proven 21:40 — one in-cluster load of /youtube/benin made 8 API calls, all counted as 192.168.1.101.
  3. Effect: the whole site shares 100 API calls/min. A /youtube page needs 6-10. Today since 15:12: 9 minutes with
     429s (20:57-21:04, 21:16; 2,660 refusals) while GPTBot (639 requests in 6 h) and OAI-SearchBot crawled — every
     reader got "Contenu momentanément indisponible" in those minutes. The "unexplained burst" was these bots.
- What changes (this CR, NDP only):
  1. Web deployment env `API_INTERNAL_URL=http://nouvellesdupays-api.nouvellesdupays.svc.cluster.local:4000`
     (kubectl set env on .51; one rolling restart). Page rendering calls the API inside the cluster.
  2. API `app.js`: rate-limit `allowList` for calls from the cluster pod network (10.42.0.0/16) that carry no
     X-Forwarded-For (only in-cluster callers; public traffic always has one from the ingress). Test added.
     API build + rollout.
  Not in this CR (next, separate): ingress-nginx `use-forwarded-headers` + `proxy-real-ip-cidr` 192.168.1.101/32 so
  browser-side API calls are limited per real visitor — global ingress setting, also affects bikocartridges,
  kendebabi, livbiko; needs ARR's X-Forwarded-For checked first.
- Why: bots crawling the site make it unavailable for everyone; render path also skips the hairpin (faster pages).
- Class: HIGH (Get-ChangeRisk 11-18: infrastructure / environment variables / rate limits). Window below.
- Risks: (1) page rendering no longer rate-limited at all — a heavy crawl now loads the API and Postgres instead of
  being refused (2-core node; watch CPU / iowait); (2) wrong service name or port -> pages show "indisponible"
  (checked by the CI build against the in-cluster URL before the window); (3) two ~10 s restarts.
- Rollback: `kubectl set env deploy/nouvellesdupays-web API_INTERNAL_URL-` (~1 min) and API rollback tag from the
  live imageID; recovery point.
- Checks after: one in-cluster /youtube/benin load -> API log shows the calls from a 10.42.x address and no 429;
  public calls still limited (101 quick public /api/countries calls from this host -> 429 appears); /youtube and
  sitemap sample 200; node CPU/iowait 10 min; API tests; Test-Build 8/8 (no public bursts from this host before it).
- Window: proposal 11-19 after the channel-metrics check (~08:00 UTC, 30 minutes), or a time you name.
- Approval: "approve CR-2026-11-18-05", "approve CR-2026-11-18-05 window now" (owner, 11-18 ~21:50 UTC).
- Result: deployed 22:05-22:07, NDP known-good #273 (8a77519), API 22a18527 (rollback-0f15043c), web env
  API_INTERNAL_URL set in the cluster; recovery point 2026-11-18_21-51-03_before-cr-2026-11-18-05-ndp-in-cluster-a.
  Rendering calls now come from the web pod (10.42.x), 150 in-cluster calls all 200, public API still limited
  (x-ratelimit headers), 31 public pages 200 with the public bucket untouched, 0 x 429 in 5 min, API tests 173/173,
  Test-Build 8/8. Public /youtube 0.73-1.11 s (was 1.7-3.6 s). Slip: the first commit overwrote the existing
  rate-limit test; restored before the build (8a77519). Next: ingress forwarded headers (separate CR).

### CR-2026-11-18-04  NDP on-prem: web pod CPU limit 250m -> 500m
- Requested by: owner (chose "Web CPU" 11-18 ~20:50) after CR-2026-11-18-03 missed its speed target.
- Evidence (11-18 20:49 UTC, read-only): over 5 direct /youtube loads the web container was throttled in 56 of 79
  CFS periods, 5.95 s throttled in total (~1.2 s per page). Node dr-rke2 (single node, 2 vCPU, shared with NDP api +
  Postgres + worker CronJobs, bikocartridges, kendebabi/woyo mirrors and the RKE2 control plane): 639m used (31%),
  vmstat 29-71% idle, 8-39% iowait, load 1.4-2.1. Requests 1825m (91%), limits 2300m (114%).
- What changes: on .51 only, `kubectl -n nouvellesdupays set resources deploy/nouvellesdupays-web -c web
  --limits=cpu=500m` (memory limit 256Mi and requests 20m / 64Mi unchanged; replicas stay 1). One rolling restart.
  The setting lives in the cluster (the on-prem values were set by kubectl, `infra/k8s/07-web.yaml` is the old OKE
  manifest with 500m / 2 replicas); the nightly dr-image-rollout only restarts, so it keeps the new limit. Recorded
  in MAINTENANCE_LOG.
- Why: /youtube rendering waits for CPU; cutting the throttling is the direct fix.
- Class: HIGH (Get-ChangeRisk 11-18: infrastructure / production resources). Window below.
- Risks: (1) the web pod may use up to 0.5 core during a burst, taking CPU from the API, Postgres or the control plane
  on a 2-core node — limits go to 2550m (127% of the node), requests unchanged so scheduling is unaffected;
  (2) the nightly kaniko builds (04:10-04:20) run with web bursts — slower builds, not failures; (3) ~10 s restart.
- Rollback (one command, ~1 min): `kubectl ... set resources deploy/nouvellesdupays-web -c web --limits=cpu=250m`.
  Triggers: API p50 slower than before by > 50 %, a pod in CrashLoop or OOM, node idle < 10 % for 5 min, any
  Test-Build failure.
- Checks after: throttled periods per /youtube load (before 56/79 over 5 loads); 10 timed loads direct + public
  (before ~1.5 s typical direct); API /api/countries and /api/youtube/directory times before vs after; node top +
  vmstat for 10 minutes; all NDP pods Running; Test-Build 8/8 (NDP scripts); recheck the next morning after the
  04:10 builds and 04:40 restart that the limit is still 500m.
- Window: proposal now (~21:00 UTC, low traffic), 20 minutes, or another time you name.
- Approval: "approve CR-2026-11-18-04", "approve CR-2026-11-18-04 window now" (owner, 11-18 ~21:13 UTC).
- Result: ROLLED BACK. Applied 21:15:17; /youtube direct ~1.7 s -> ~0.78 s typical, throttling 11.8 s -> 1.8 s per
  10 loads, API unchanged. Test-Build 21:16:17 7/8 (public API 429 = per-IP rate limit used up by my own public
  test loads from this host in the same minute), so rolled back per the HIGH rule at 21:16:44 (250m verified);
  Test-Build after rollback 8/8. Also found: ~2,000 API requests from this host's IP 20:56-21:04, source unknown.
  Recovery point 2026-11-18_21-14-42_before-cr-2026-11-18-04-ndp-web-cpu-limi. A retry goes back to the owner.
- Retry: owner "approve CR-2026-11-18-04 window now" (~21:24). Applied 21:25:06, known-good NDP #272. Direct /youtube
  ~0.8 s typical (was ~1.7 s); API p50 15-20 ms (was ~14 ms, worker run active); node idle 13-56% over 5 min
  (load is iowait, not CPU); Test-Build 8/8. Public /youtube from this host still 1.7-3.6 s (hairpin/haproxy path,
  not in scope). Recovery point 2026-11-18_21-25-02_before-cr-2026-11-18-04-retry-ndp-web-cp. To check 11-19:
  limit still 500m after the 04:40 restart.

### CR-2026-11-18-03  NDP web: lighter /youtube main page
- Requested by: owner ("1, write the CR", 11-18) after Claude's measurement.
- Measured before (11-18 ~17:30 UTC): /youtube HTML 563 KB (106 KB gzip), of which ~330 KB is the Next.js page data
  for the browser; 295 images, ~300 list items. The 6 API calls answer in 0.07-0.45 s; the web pod (1 replica,
  CPU limit 250m) needs 1.2-2.8 s to send the whole page (same directly in the cluster and through dr-haproxy), so
  the time is spent rendering. Client props: filter facets 41 KB, video list 24 KB.
- What changes (web only, `app/youtube/(accueil)/page.tsx` + `components/DirectoryFilters.tsx` types if needed):
  1. "Explorer par pays": the ~190 country cards with flags become, per continent, the continent link (+ the 5 African
     region links, as today) and a compact list of plain country text links with their count — no flag images, no
     card markup. Every country page stays linked from /youtube (kept on purpose: CR-2026-11-17-03 relies on these
     links for crawlers) and stays in the sitemap; flags stay on the region and country pages.
  2. The filters' client component gets only the fields it reads (countries: iso, name, continent, count;
     categories: slug, name_fr, count, parent_slug; types / languages: key, label, count; continents: key, label).
  3. "Vidéos sélectionnées": 24 videos instead of 60 (API `limit=24`).
  No API, worker or DB change. Directory cards, rankings, filters and links behave as today.
- Target (not a promise): HTML about a third smaller or better, server time for /youtube under 1 s typical, measured
  the same way before and after.
- Class: MEDIUM (Get-ChangeRisk 11-18, run alone).
- Impact / downtime: one web build + rollout (~10 s).
- Rollback: web rollback tag taken from the live imageID before the build (today cdcd6ae7).
- Checks after: CI pod web build; same measurement (size, 5 timed loads direct and public); all 565 /youtube sitemap
  URLs still 200 at a polite rate (under the 100/min API limit), unknown 404; every country link from before still
  present on /youtube; 390 px screenshot without overflow; filters still work (country, category, sort); Test-Build
  8/8 (NDP scripts).
- Approval: "approve CR-2026-11-18-03" (owner, 11-18).
- Result: deployed ~19:58 11-18, NDP known-good #271 (50b5e63), web e4efe04c, rollback-cdcd6ae7; recovery point
  2026-11-18_19-38-52_before-cr-2026-11-18-03-lighter-ndp-yout. HTML 563 -> 393 KB (-30%), gzip 106 -> 91 KB, images
  295 -> 91; all country/region/category links kept; 566/566 sitemap URLs 200, unknown 404; 390 px no overflow;
  Test-Build 8/8. Speed target NOT met: /youtube still ~1.5 s typical (0.7-3.5 s) — rendering is CPU-bound at 250m.
  Next step is an owner decision (more web CPU = HIGH, or render lower sections on demand).

### CR-2026-11-18-02  NDP web: measurement date on /youtube directory cards
- Requested by: Claude (left open by CR-2026-11-18-01).
- What changes: web only. `DirectoryCard.tsx` shows the date next to the numbers when the API gives
  `stats_measured_at` (e.g. "12 k abonnés · 3,4 M vues · au 19 nov."), with a tooltip "Statistiques au 19 novembre
  2026"; `types.ts` gains `stats_measured_at: string | null` on DirectoryEntry. No API, worker or DB change. Cards
  without stats_measured_at (approved creators, channels without channel_metrics) look as today.
- Why: the numbers come from a daily measurement; readers should see how fresh they are (brief: never present stale
  numbers as live).
- Class: MEDIUM (Get-ChangeRisk 11-18, run alone).
- Impact / downtime: one web build + rollout (~10 s). Nothing visible until the first channel_metrics run (11-19
  07:25 UTC).
- Rollback: web rollback tag taken from the live imageID before the build.
- Checks after: web build in CI pod; /youtube and a country page 200; after 11-19 07:25 a card with the date in
  French; Test-Build 8/8.
- Approval: "approve CR-2026-11-18-02" (owner, 11-18).
- Result: deployed 17:05 11-18, NDP known-good #270 (393f358), web cdcd6ae7, rollback-5eeae633; recovery point
  2026-11-18_16-50-17_before-cr-2026-11-18-02-ndp-card-measure. CI build + pages 200, Test-Build 8/8. Date visible
  from the 11-19 07:25 channel_metrics run (checked with CR-2026-11-18-01).
  Verified 11-19 after the 08:25 run: /youtube has 38 "Statistiques au ..." titles and "au 19 nov." on the cards. Done.

### CR-2026-11-18-01  NDP: channel statistics for every directory channel; discovery on active categories
- Requested by: Claude (follow-ups left open by CR-2026-11-17-04 and CR-2026-11-17-02).
- What changes:
  1. Worker `apps/worker/src/channel-logos.js` (daily, already calls channels.list for all ~305 directory channel ids,
     ~7 units): also writes subscribers (unless hidden), total views and video count to `channel_metrics`
     (migration 020) for every returned channel, keyed like the directory (YouTube channel id). No extra API call,
     no extra quota. The audience_metrics rows for the 10 linked accounts stay as today.
  2. API `youtubeDirectory.js`: a channel card reads its latest channel_metrics subscribers / total views when no
     linked account has them, with the measured date ("Statistiques au <date>"); nothing invented, hidden counts stay
     absent. Today 32 of 334 cards show subscribers; expected ~300.
  3. Worker `creator-agents.js` TOPIC_CATEGORY: YouTube topics mapped to switched-off categories move to active ones:
     Sport -> sports-news (was other-sports), Physical_attractiveness -> fashion (was beauty),
     'Lifestyle_(sociology)' -> lifestyle-living (was the main category), Health -> fitness-wellness (was
     personal-development). Existing candidates' links are not changed.
- Why: CR-11 found 32 subscriber counts for 334 channels; new discovery candidates should not land in switched-off
  categories.
- Class: MEDIUM (Get-ChangeRisk 11-18, run alone). No schema change (channel_metrics exists since migration 020).
- Impact / downtime: worker build (CronJobs pull it on the next run) + api rollout (~10 s). First metrics on the next
  daily logo run (or one run started by hand during the change).
- Rollback: worker and api rollback tags (taken from the live images); `DELETE FROM channel_metrics` (only this step
  writes it).
- Checks after: worker + API tests; one run: ~7 units, rows in channel_metrics = channels returned x metrics shown;
  directory cards with subscribers ~300, values equal to the YouTube API response for 3 sampled channels, hidden
  counts absent; /youtube 200; Test-Build 8/8.
- Approval: "approve CR-2026-11-18-01".
- Result: deployed 15:20 11-18, NDP known-good #269 (72a0773), worker 25d4ed8b / api 0f15043c; rollback-b011f104 /
  rollback-6ba17846; recovery point 2026-11-18_15-01-34_before-cr-2026-11-18-01-channel-metrics. Tests worker 119/119,
  API 171/171, Test-Build 8/8. The logo step runs at most every 20 h, so the first channel_metrics rows come at
  11-19 07:25 (not forced); checks listed above to run then. Card date display: separate small web change.
  Verified 11-19: first run at 08:25 (not 07:25), channel_metrics 915 rows = 305 channels x subscribers /
  total_views / video_count. Done.

### CR-2026-11-17-02  NDP migration 020: nested category hierarchy + admin category management
- Requested by: owner, 11-17 ("MASTER PROMPT - REDESIGN NOUVELLESDUPAYS YOUTUBE PAGE WITH NESTED CATEGORIES").
- Audit (read-only, 11-17): the hierarchy already exists and is platform-neutral - `creator_categories` (49: 7 top +
  42 sub, slug/parent_slug/name_en/name_fr/sort_order) linked to `creators` (25 approved, 547 candidates, 44 rejected),
  and creators own `social_accounts` (youtube 775, facebook 335, x 315, instagram 251, tiktok 96), so /facebook and
  /tiktok can reuse it unchanged. Gaps: no active flag or descriptions; categories are seeded by migration only (admin
  API is read-only: `GET /api/admin/creator-categories`); the 312 directory channels from `video_channels` (no creator
  record) have no subcategory, only a topic. Admin merge of creators already exists (`POST /api/admin/creators/:id/merge`).
- What changes:
  1. `db/migrations/020_category_hierarchy.sql` (additive, idempotent):
     - creator_categories + `active` (default true), `description_fr`, `updated_at`; index (parent_slug, sort_order).
     - The brief's 8 main categories and 70 subcategories, French names on the site (owner rule: French page = all
       French). Existing slugs kept and mapped (news-media = Actualités et médias; politics -> under the new
       politique-societe; digital-gaming -> Technologie et jeux vidéo, ...); new slugs added; existing slugs with no
       place in the brief are re-parented where the brief has them (dance -> culture) or set `active = false`.
       **No category or link deleted.** Full old -> new table in `ops/release-category-hierarchy/mapping.md` for the
       owner before the window.
     - New `video_channel_category_links (channel_key, category_id, is_primary)`; channel_key = YouTube channel id or
       lowercased URL (the CR-11 grouping), so one canonical channel however many rows/countries it has; indexes on
       category_id and channel_key.
     - New `channel_metrics (channel_key, metric, value, source, measured_at)` - append-only like audience_metrics,
       for directory channels with no social_accounts row (added 11-18 from CR-2026-11-17-04, owner option A);
       index (channel_key, metric, measured_at DESC). The CR-04 worker step then writes subscribers / total views /
       video count there after this window.
  2. Classification of the 312 channels + 25 approved creators into subcategories: proposed by rules (current topic,
     rail, name/description keywords) into a CSV for **owner review**, applied only after review (brief: do not
     publish wrongly classified channels). Until then a channel shows under its main category only.
  3. Admin API: `POST/PATCH /api/admin/creator-categories` (create, rename, describe, move, reorder, deactivate; no
     delete), `PUT /api/admin/channel-categories/:key` (several subcategories, one primary). Admin page
     `/admin/categories` (tree, up/down reorder, active toggle) + category picker on /admin/creators and a channel
     classification view; CSV export/import of classifications.
  4. Directory API: filter by any level (a parent matches its subcategories); inactive categories hidden publicly.
- Not here: nested pages (-03), statistics (-04), recent-video performance / engagement / growth (needs the quota
  decision), Facebook/TikTok pages (later; no Facebook/Instagram fetching).
- Class: HIGH (Get-ChangeRisk 11-17: database migration).
- Window: ~40 min, any hour (additive; readers unaffected). Steps: recovery point -> rehearsal in one transaction on
  production, rolled back -> api build -> migrate job -> rollout -> checks.
- Rollback: `reverse.sql` (drop the new table/columns, delete only rows the migration inserted, restore names/parents
  from the saved copy) or the recovery point's DB dump; api rollback tag.
- Checks after: API tests (hierarchy, deactivate hides, several subcategories, parent filter); all 49 old slugs
  present; every existing link resolves; /youtube and /creators 200; Test-Build 8/8.
- Approval: "approve CR-2026-11-17-02" + "approve CR-2026-11-17-02 window now"; the classification CSV is approved
  separately by the owner.
- Result: done 12:28 11-18 (option B), NDP known-good #267 (e0b7de5). Migration 020 applied ~11:45 after two rehearsals
  (83 categories, 78 on = 8 + 70, 49 old slugs kept, 1,429 links 0 broken). api 6c75d01c / web 59622da6;
  rollback-9cf6bfbd / rollback-d616781d; reverse.sql; recovery point before-cr-2026-11-17-02-migration-020-ca.
  API 169/169, Test-Build 8/8. /admin/categories not browser-checked (no admin session in the automation tab).
  Open: owner CSV import; worker topic map to switched-off slugs (harmless); channel_metrics writer; CR-03.

### CR-2026-11-17-03  NDP /youtube nested pages (region, country, category, subcategory)
- What changes (web + read-only API, after -02):
  - Routes generated from the database: `/youtube/<region>` (afrique, afrique-de-l-ouest, afrique-centrale,
    afrique-de-l-est, afrique-du-nord, afrique-australe, europe, asie, moyen-orient, amerique-du-nord,
    amerique-du-sud, oceanie), `/youtube/<country>` (existing, kept), `/youtube/<country>/<category>`,
    `/youtube/<country>/<category>/<subcategory>`, `/youtube/categorie/<category>[/<subcategory>]`. Existing
    `/youtube/<slug>` video landing pages keep working (country/region slugs checked first, as today).
  - Each page: breadcrumb, French description, nested menu (region -> country -> category -> subcategory, with
    counts), channel count, search + filters, cards, popular channels; empty subcategories hidden; 404 for unknown
    slugs; canonical, Open Graph, JSON-LD BreadcrumbList + ItemList; sitemap lists non-empty pages only.
  - Filters update the list without a full page reload (client navigation; the URL still holds the filters).
  - Cards add the subcategory, and "Chaîne officielle vérifiée" only where account verification says so.
- Class: MEDIUM (Get-ChangeRisk 11-17). Rollback: api/web rollback tags. Checks: route tests per level incl. 404s;
  crawl of every generated URL (200, none empty); 390 px; tracking unchanged; Test-Build 8/8.
- Approval: "approve CR-2026-11-17-03".
- Result: done 14:14 11-18, NDP known-good #268 (bc03609). api 6ba17846 / web 5eeae633; rollback-6c75d01c /
  rollback-59622da6; recovery point 2026-11-18_12-30-07_before-cr-2026-11-17-03-nested-youtube-p. 565 sitemap URLs 200,
  unknown pages 404 (fixed a soft-404 from the CR-11 loading skeleton, and an API rate-limit failure read as 404),
  390 px OK, API 170/170, Test-Build 8/8. Subcategory pages fill when the owner imports the classification CSV.

### CR-2026-11-17-04  NDP worker: YouTube logos for every directory channel (narrowed 11-18)
- Finding 11-18 (before any code): the directory has 305 valid YouTube channel ids; only 10 have a `social_accounts`
  row, and `social_accounts_owner_check` requires a publisher, creator or discovered source - so statistics for the
  other 295 cannot go to `audience_metrics` without a schema change (HIGH). Stopped and asked; owner chose option A
  ("A, write the CR").
- What changes now (no schema change): a worker step, at most once per 24 h, calls `channels.list` (part=snippet,
  statistics; 50 ids per call, ~7 units) for every directory channel id and
  1. sets `video_channels.logo_url` (column exists, empty for all 305) from the channel thumbnail on every row of that
     channel, only where it is empty or was set by this step (a curated logo is never overwritten);
  2. writes subscribers (unless hidden), total views and video count to `audience_metrics` for the channels that
     already have a youtube `social_accounts` row (same rules as youtube-audience.js);
  3. records its units in `agent_runs` (agent 'youtube') so discovery's daily budget counts them.
  Channel ids the API does not return are logged, not changed.
- Moved to CR-2026-11-17-02 (migration 020): `channel_metrics` table; after that window this step also writes
  subscribers / views / video count for the other directory channels.
- Old text (kept for the record): "stores logo, subscribers (unless hidden), total views, video count in
  `audience_metrics` with measured_at ... Fills the CR-11 gaps (27 logos, 32 subscriber counts)."
- Not here: recent-video performance, engagement, activity and growth rankings - they need playlistItems/videos.list
  (~4,300 units/day) -> owner decision on quota (Google increase request vs less discovery) first.
- Class: HIGH - Get-ChangeRisk 11-17 said MEDIUM; re-run 11-18 on the narrowed wording said HIGH, so HIGH (rule: the
  higher class). Window: now, ~30 min (worker build + one run; readers unaffected). Rollback: worker rollback tag;
  `UPDATE video_channels SET logo_url = NULL WHERE logo_url` set by this step (saved list of ids in the release
  folder); metrics rows additive (removable by source + measured_at). Checks: worker tests; one run: units ~7, logos
  set, no curated logo changed, metrics only for linked accounts, hidden counts stay hidden; /youtube shows the
  logos; Test-Build 8/8.
- Approval: "approve CR-2026-11-17-04" (11-18); narrowed scope "A, write the CR" (11-18); needs
  "approve CR-2026-11-17-04 window now".
- Result: done 11:28 11-18, NDP known-good #266 (6f9781f), worker b011f104, rollback-d2a8c8ec; recovery point
  before-cr-2026-11-17-04-window-channel-l. First run: 305/305 channels returned, 475 logo rows, 30 metrics, 7 units;
  directory 327/334 with a logo (was 27); Test-Build 8/8. Finding: dr-image-sync-* rebuild from GitHub main daily
  04:10-04:20 and dr-image-rollout restarts api/web 04:40 - push only approved changes.

### CR-2026-11-17-01  NDP API: stop fetching youtube.com/feeds/videos.xml
- Requested by: Claude (finding during CR-2026-11-16-11; rule: bot UA only, respect robots.txt).
- Finding: https://www.youtube.com/robots.txt (re-read 11-17) has `User-agent: *` / `Disallow: /feeds/videos.xml`. The API
  fetches it in two places:
  1. `apps/api/src/videoChannels.js` `latestVideo()` - for every YouTube row on each `/api/countries/:iso/video-channels`
     panel and `/api/youtube/channels` (one request per channel per uncached page view; up to 8 s each).
  2. `apps/api/src/youtube.js` `verifyChannel()` - keyless fallback when a channel is submitted by id (`/channel/UC...`)
     and the Data API key is missing or fails (quota is fully used by discovery, so this path is live).
- What changes (old -> new):
  1. `latestVideo()` removed; `withLatestVideos()` returns the rows with `latest_video: null` (field kept, so the web
     and its types do not change). The web already handles null (`VideoSequence.tsx` plays the channel's uploads
     playlist through the IFrame player - the path most channels have used since 2026-10, when the feed began answering
     404 for most of them). The "latest video" title line disappears where a feed still answered.
  2. `verifyChannel()` id path: the channel page `https://www.youtube.com/channel/<id>` (allowed by robots.txt) instead of
     the feed - the existing page branch already reads og:title and the channel id; 404 still = invalid.
  3. Test `apps/api/test/youtube.test.js`: fake YouTube serves `/channel/<id>` instead of `/feeds/videos.xml`; new test that
     `withLatestVideos` makes no request.
- Why: robots.txt compliance; also removes up to one 8-s external request per channel from page loads
  (`/api/youtube/channels` took 1.8-3.6 s).
- Class: MEDIUM (Get-ChangeRisk 11-17, run alone).
- Impact / downtime: api rollout only (~10 s per pod). No DB change, no web change.
- Rollback: rollback tag of the current api image (`rollback-<digest8>`, taken before the build) -> set image + rollout.
- Checks after: CI api tests; grep confirms no `feeds/videos.xml` left in apps/api/src; `/api/youtube/channels` and
  `/api/countries/CI/video-channels` 200 with `latest_video` null and faster; /africa/cote-divoire video rail plays
  (uploads playlist); /youtube 200; Test-Build 8/8.
- Approval: "approve CR-2026-11-17-01".
- Result: done 01:40, NDP known-good #265 (ac873ff), api 2f90a226, rollback-0b737600; recovery point
  2026-11-17_01-03-27_before-cr-2026-11-17-01-stop-feeds-video. Endpoints 0.1-0.4 s (were 1-3 s), latest_video null,
  tests 163/163, Test-Build 8/8.

### CR-2026-11-16-11  NDP /youtube redesign — phase 1 (layout from existing data)
- Requested by: owner, 11-16 ("MASTER DEVELOPMENT PROMPT — REDESIGN NOUVELLESDUPAYS YOUTUBE PAGE").
- Audit (read-only, 11-16 ~17:40): `/youtube` = `apps/web/src/app/youtube/page.tsx` (238 lines): heading, "par pays"
  cards (country pages with >= 5 approved creators), creator ranking (>= 5 ranked), video_channels grid, landing videos.
  Data: `video_channels` 537 rows / 188 countries (category live_now 209, national_tv 193, local_voices 128,
  africa_voices 7; 475 with a YouTube channel id; **0 logos stored**); `creators` 25 approved (21 media_brand,
  4 individual; 49 creator categories, 1159 links; rankings 1666 rows); `youtube_videos` 42 (submitted landing videos).
  **No stored per-channel recent videos, view counts per video or live status.** Tracking events exist
  (`lib/trackingEvents.ts`: YouTubeLandingPageView, YouTubeClick, YouTubePlay, WatchOnYouTube, Search); the channel
  cards on /youtube fire none today. youtube.com/robots.txt disallows `/feeds/videos.xml` -> recent videos/live only via
  the Data API (quota 8000/day, fully used by discovery today).
- What changes (phase 1 = no DB change, no new YouTube calls):
  1. `/youtube` rebuilt as sections with a sticky tab bar (anchors, horizontally scrollable on mobile): Découvrir,
     Chaînes d'info, Créateurs indépendants, Pays, Catégories, Classements. (Live, Tendances, Sélection de la rédaction
     come in phase 3 when data exists - not shown empty.)
  0. Language (owner 11-16: "when the page is french everything should be in french"): every label, tab, filter,
     button, empty state, methodology text, metadata and alt text in French; the brief's English wording is translated
     (e.g. "EN DIRECT", "Sélection de la rédaction", "Tendances en Afrique"). Channel names/video titles stay as published.
  2. Hero: heading "NouvellesDuPays — Vidéos & Médias", subtitle in French,
     one featured channel (top-ranked approved creator), search + country / category / type / language filters,
     reset. Filters are URL query params (shareable, kept when switching tabs), applied server-side.
  3. Channel directory: one card component for video_channels and approved creators (avatar or initial, name, flag +
     country, type, primary category, subscribers only when known, YouTube link). Sorting: subscribers, total views
     (creators only), alphabetical; "recently active"/"growth"/"engagement" only where creator snapshots exist, else
     hidden. Paginated (24 per page). Nothing invented: missing numbers are left out.
  4. Independent creators section: approved creators with creator_kind individual, with their public profile
     description; separate from institutional channels. Rankings section: existing ranking + top by country/category +
     fastest growing (from existing creator_rankings/snapshots) + a methodology block ("performance, not accuracy").
  5. Country explorer: Africa first (every African country with >= 1 channel or creator: flag, channel count,
     categories), then the other continents; links to /youtube/<country> where a country page exists (existing route).
  6. New read-only API `GET /api/youtube/directory` (filters + sort + pagination over video_channels + approved
     creators, cached 5 min) - existing endpoints unchanged.
  7. Tracking: channel/creator card clicks fire the existing YouTubeClick / WatchOnYouTube events; search/filter use
     the existing Search event (no new event names, no duplicates).
  8. SEO: title, description, canonical /youtube, Open Graph, JSON-LD ItemList of channels, alt text, links to
     country pages.
- Not in phase 1 (each its own CR): **phase 2** taxonomy migration (channel_type with the brief's 12 types + mapping of
  the brief's 14 categories onto the existing 49 + per-channel classification list for owner review - HIGH, DB
  schema); **phase 3** recent-videos worker (playlistItems 1 unit/channel every 3 h ~3,800 units/day + videos.list for
  stats/live on known live-stream ids every 15 min ~500/day) -> latest video on cards, Tendances Afrique / Monde,
  EN DIRECT (only when confirmed live by videos.list < 20 min ago), Sélection de la rédaction (admin picks) - HIGH,
  needs a quota decision (YouTube quota-increase request, or less discovery); **phase 4** channel logos via
  channels.list (1 unit/50 channels).
- Class: to be confirmed by Get-ChangeRisk alone before apply (web + new read-only endpoint, like #255/#261: MEDIUM).
- Impact / downtime: web + api rollout (~10 s per pod, as earlier builds). Existing routes (/youtube/<slug>, /creators,
  /creators/<slug>) unchanged.
- Rollback: rollback tags for api and web taken before the build (manifest PUT), as #261.
- Checks after: CI (api tests + web build); /youtube 200 desktop + mobile screenshots; every filter and sort returns
  results and combines; all 537 channels + 25 creators reachable via the directory (count check against the DB);
  no duplicate cards; country links 200; tracking events seen in the existing analytics (browser network + DB);
  Lighthouse-style load check; Test-Build 8/8.
- Approval: "approve CR-2026-11-16-11".
- Result: done 20:53, NDP known-good #264 (0ac786b). api 0b737600 / web 296e4f87; rollback-e59ae63f / rollback-7d7e3ac3;
  recovery point 2026-11-16_17-55-15_before-cr-2026-11-16-11-youtube-redesign. 334 directory entries (558 rows grouped:
  one card per channel), Africa first, French country names, 390 px fits, tracking stored once, API 162/162, Test-Build 8/8.
  Open: payload 540 KB; 27 logos / 32 subscriber counts; growth after 30 days; /feeds/videos.xml fetch -> own CR.

### CR-2026-11-16-10  OCI IAM policy + 30-day delete rule for bucket tekeche-mongo-backups
- Requested by: Claude (CR-09 left the lifecycle rule undone: InsufficientServicePermissions).
- What changes (OCI tenancy lr14abpkfrxj, uk-london-1):
  1. New IAM policy `tekeche-backup-bucket-policy` in the **root** compartment (where the same NDP policy
     `nouvellesdupays-backup-bucket-policy` lives, created 07-26), one statement, mirroring NDP's second statement:
     `Allow service objectstorage-uk-london-1 to manage object-family in compartment id <tekeche-pub ocid> where
     target.bucket.name = 'tekeche-mongo-backups'`
     It lets only Oracle's Object Storage service (not a user or machine) manage objects, only in that one bucket - the
     permission lifecycle rules need to delete. No user, group or dynamic-group gets anything.
  2. Lifecycle rule on the bucket: `delete-after-30-days`, DELETE, 30 DAYS, prefix `tekeche/`, enabled.
- Why: without it the bucket keeps every hourly backup forever (~30 MB/day); 30 days matches "a month of hourly restore
  points" and caps it at ~1 GB.
- Class: Get-ChangeRisk said MEDIUM; raised to HIGH by Claude (IAM = security; CHANGE_APPROVAL "when in doubt, higher").
- Impact / downtime: none. Effect: backups older than 30 days disappear from the bucket (the first ones, 11-03, on ~12-03).
  Local copies on BIKODC are unaffected (still 14 days).
- Rollback: `oci os object-lifecycle-policy delete` on the bucket; `oci iam policy delete` of the new policy. Neither
  touches stored objects.
- Recovery point: Tekeche New-RecoveryPoint; current policy list (names + statements) saved into it.
- Checks after: policy shows the 1 statement; lifecycle policy shows the rule enabled; NDP policy unchanged; an upload
  run still works (Test-Build 11/11).
- Window (proposed): now, 15 minutes.
- Approval: "approve CR-2026-11-16-10 window now" (owner, 11-18 ~22:20 UTC).
- Result: done 22:24-22:26 11-18. Policy tekeche-backup-bucket-policy ACTIVE (1 statement); lifecycle rule
  delete-after-30-days enabled (prefix tekeche/); other 15 root policies unchanged; 22:25 upload OK; Test-Build 11/11.
  Recovery point 2026-11-18_22-22-47_before-cr-2026-11-16-10-oci-policy-and-l (+ policy snapshot).

### CR-2026-11-16-09  Tekeche MongoDB backups copied off-site to OCI Object Storage
- Requested by: owner, 11-16 ("c, write the CR"). Replaces CR-08 step 2 (copy to BIKODC1: SYSTEM got Access denied on
  `\\192.168.1.102\c$`; nothing was created there).
- Today (after CR-08): `Tekeche-MongoDB-Backup` runs hourly at :10 on BIKODC -> `C:\backups\tekeche\<timestamp>`
  (26 `.json.gz`, ~1.3 MB), 14 days kept. Only copy is on BIKODC (same ESXi host as .53 unless the owner says otherwise).
- What changes:
  1. OCI (tenancy lr14abpkfrxj, region uk-london-1, the CLI profile already on BIKODC): a new **private** bucket
     `tekeche-mongo-backups` (no public access, Oracle-managed encryption, Standard tier), with a lifecycle rule that
     deletes objects older than **30 days**. Compartment: the Tekeche compartment if one exists, else the tenancy root
     (where the only bucket today, bucket-20260523-2129, is) - recorded at apply.
  2. New script `ops\scripts\Copy-TekecheBackupOci.ps1` + task `Tekeche-Backup-Offsite` (hourly at :25, SYSTEM, same as the
     backup task): uploads each backup folder not yet uploaded to `tekeche/<timestamp>/<collection>.json.gz` with
     `oci os object bulk-upload --no-overwrite` and the existing CLI config passed explicitly (`--config-file`); checks the
     object count matches the folder; appends one line per run to `C:\backups\tekeche\offsite.log`; exits non-zero on any
     failure. No keys or passwords in the script.
  3. Test-Build: the CR-08 backup check also requires the newest folder to be listed in the bucket.
- Why: a copy that survives losing BIKODC or the whole ESXi host; worst-case loss stays ~1 h.
- Class: HIGH (Get-ChangeRisk 11-16 ~17:00).
- Impact / downtime: none for users. ~1.3 MB upload per hour; ~1 GB kept in the bucket after 30 days (cost: within the
  free Object Storage allowance or a few pence a month).
- Risks / owner points:
  - The backups hold personal data (users, phone numbers, bookings). They leave the building, stored in OCI London,
    private, encrypted at rest by Oracle. If you want them also encrypted before upload (key kept on-prem), say so -
    that is a bigger change.
  - SYSTEM must be able to read the CLI config and API key (`C:\tekeche-ops\oci\...`); if it cannot, the script stops
    and that access change comes back for approval.
  - The API key used is the existing one (its user's rights decide whether it can create the bucket); if refused,
    the owner creates the bucket in the OCI console.
- Rollback: unregister `Tekeche-Backup-Offsite`; `git revert` of the script/Test-Build commit. The bucket and objects
  are left (deleting them only on owner request).
- Recovery point: Tekeche New-RecoveryPoint + export of the task list.
- Checks after: run the upload by hand -> objects for the newest backup in the bucket, count 26, sizes match; second run
  uploads nothing new (no duplicates); download one object and gunzip it to prove it reads; bucket is not public
  (`public-access-type NoPublicAccess`); lifecycle rule shown; Test-Build passes; the next :25 run succeeds.
- Window (proposed): now, 45 minutes.
- Approval: "approve CR-2026-11-16-09 window now" (owner, 11-16 ~16:57 UTC).
- Result: bucket tekeche-mongo-backups in tekeche-pub (NoPublicAccess, 0 PARs); task Tekeche-Backup-Offsite (SYSTEM, :25);
  16 backups uploaded and verified; download/gunzip OK; idle run "nothing new"; Test-Build 11/11; Build #66; scheduled
  17:25 run OK. NOT done: 30-day lifecycle rule - InsufficientServicePermissions (needs an IAM policy for the Object
  Storage service = new owner decision). Script bug ($done/$DONE same variable) found and fixed inside the window.

### CR-2026-11-16-08  Tekeche MongoDB backups: hourly, copied to BIKODC1, freshness check (option B)
- Requested by: owner, 11-16 ("B now, write the CR"), after the finding that Tekeche production runs on one standalone
  MongoDB 4.4.31 on dr-mongo 192.168.1.53 (no replica set since 09-13). Option A (new replica set) stays a later project.
- Today: scheduled task `Tekeche-MongoDB-Backup` on BIKODC runs `tekeche-api\scripts\backup.js` once a day at 01:00
  (JSON export of every collection from the .env URI, gzip, `C:\backups\tekeche\<timestamp>`, keeps 14 days; 26
  collections, ~1.4 MB/run, 19 MB total). Only copy is on BIKODC. Restore: `scripts\restore.js`. Worst case today: up to
  24 h of bookings/users lost, and losing BIKODC loses the backups too.
- What changes (BIKODC + BIKODC1 only; nothing on .53, tekeche-api, PM2, IIS, .env):
  1. Task `Tekeche-MongoDB-Backup`: trigger daily 01:00 -> **every hour** (at :10). Same script, same 14-day pruning
     (~336 copies, ~470 MB on C:). backup.js unchanged.
  2. New script `ops\scripts\Copy-TekecheBackup.ps1` + task `Tekeche-Backup-Copy` (hourly at :25): copies new backup
     folders to `\\192.168.1.102\c$\backups\tekeche-copy` (BIKODC1), checks each copied folder has the same files and
     sizes, keeps 14 days there, logs one line per run to `copy.log`. Runs as the same account as the existing tasks.
  3. Test-Build.ps1: new check "Tekeche backup fresh": newest `C:\backups\tekeche` folder < 2 h old with >= 20
     `.json.gz` files, and the same folder present on BIKODC1.
- Why: cuts the worst-case data loss from ~24 h to ~1 h and keeps a copy off BIKODC until a replica set exists.
- Class: HIGH (Get-ChangeRisk 11-16 ~16:50).
- Impact / downtime: none for users. An hourly read of ~1.4 MB from .53 (seconds). ~470 MB disk on each of BIKODC and
  BIKODC1.
- Risks: the hourly export runs while bookings are written (each collection is read separately, so a backup is not
  a single point-in-time snapshot - same as today's nightly one); BIKODC1 share/permissions may need fixing (if the
  copy cannot write there, step 2 stops and comes back as its own decision).
- To confirm by owner: is BIKODC1 on a different physical host than BIKODC and .53? If it is the same ESXi host, the
  copy protects against losing the BIKODC VM, not the host.
- Rollback: task trigger back to daily 01:00 (exported to `ops\recovery-points\...\Tekeche-MongoDB-Backup.xml` before
  the change); unregister `Tekeche-Backup-Copy`; `git revert` of the script/Test-Build commit. Copies on BIKODC1 kept
  (deleting them only on an owner-approved list).
- Recovery point: Tekeche New-RecoveryPoint (fixed by CR-06) + export of the existing task XML.
- Checks after: run the backup task once by hand -> new folder, 26 files; run the copy task -> same folder on BIKODC1,
  identical file sizes, copy.log line; Test-Build passes with the new check; next two scheduled runs (:10 and :25)
  succeed (LastTaskResult 0).
- Window (proposed): now, 45 minutes.
- Approval: "approve CR-2026-11-16-08 window now" (owner, 11-16 ~16:45 UTC).
- Result: step 1 done (hourly from 17:10; runs 16:47 manual and 17:10 scheduled OK, 26 files); step 3 done (Test-Build
  check, Build #65); step 2 STOPPED - SYSTEM "Access is denied" on \\192.168.1.102\c$, nothing created; replaced by
  CR-09 (owner chose OCI). Done.

### CR-2026-11-16-07  NDP: reject gambling candidates 144 and 524
- Requested by: Claude (follow-up of CR-05).
- What changes: 2 rows in NDP `creators`, through `PATCH /api/admin/creators/:id` in the owner's logged-in /admin
  session (no direct SQL): review_status candidate -> **rejected**, reviewer_note (was empty) -> "Rejeté : chaîne de
  jeux d'argent / paris (CR-2026-11-16-07)". Nothing else on the rows changes.
  - 144 tunisien-casino-streamer-letsgivetaspin "TUNISIEN-CASINO STREAMER - LETSGIVETASPIN" (country 47 = TN,
    @tunisien-casinostreamer, from job 79)
  - 524 1xbet-philippines "1XBET Philippines" (no country, Southeast Asia, @1xbetph, bio "Official YouTube channel of
    1XBET Philippines. High Stakes High Reward!", from job 198)
- Why: gambling channels are not creators for the directory; CR-05 stops new ones, these two came in before it.
- Class: MEDIUM (Get-ChangeRisk 11-16 ~16:40, wording: "mark 2 creator candidates (gambling channels) as rejected with a
  reviewer note via the admin UI"). No window needed.
- Impact: none public (candidates are never shown); the review queue drops by 2. A rejected channel is "known", so
  discovery will not add it again.
- Rollback: PATCH both back to review_status candidate, reviewer_note "" (values recorded above).
- Checks after: GET /api/admin/creators/144 and /524 show rejected + note; public /api/creators unchanged (25).
- When: any time after approval, ~10 minutes, owner logged in to /admin in the automated Chrome tab.
- Recovery point: NDP New-RecoveryPoint before.
- Approval: "approve CR-2026-11-16-07" (owner, 11-16 ~16:34 UTC).
- Result: NDP recovery point dump 2026-11-16T16-35-45Z; PATCH 16:39:44 both 200, read back rejected + note; public
  /api/creators 25; Test-Build 8/8; Set-KnownGood (NDP registry #263). Correction: 524 already had a note
  ("Suggestion : rejeter (paris sportifs) - détecté sur le nom, à confirmer"), not empty - that is its rollback value. Done.

### CR-2026-11-16-06  Tekeche New-RecoveryPoint: dump the production MongoDB and fail loudly
- Requested by: Claude (found 11-16 while doing CR-05).
- Finding (read-only checks 11-16 16:10-16:20): `ops/scripts/New-RecoveryPoint.ps1` dumps `127.0.0.1:27017` (BIKODC's
  own mongod). That node answers hello with no set name, not primary, not secondary, so mongodump fails
  ("NotPrimaryOrSecondary"). The script hides the error (`| Out-Null`) and then crashes on `.Sum`. Recovery points
  2026-11-05_01-00-43 and 2026-11-16_15-32-42 have **empty** db-dump folders (up to 10-18 they were ~11 MB).
  Production tekeche-api (.env, unchanged since 09-13) uses a **standalone** mongod on 192.168.1.53 (hello: no set
  name, writable primary); /health ok on :5000 and api.tekeche.com. The nightly `Tekeche-MongoDB-Backup` task
  (backup.js, uses the .env URI) is fine: 2026-11-16T01-00-03, 1.4 MB, all collections.
- What changes: New-RecoveryPoint.ps1 and Invoke-Rollback.ps1 read MONGODB_URI from `tekeche-api\.env` instead of a
  hard-coded 127.0.0.1 URI (no password in the script any more); mongodump errors are shown and stop the script
  (no recovery point is reported as created without a database dump); the dump size is checked (> 0).
  Test-Build.ps1's Mongo check reviewed for the same hard-coded URI.
- Not in this CR: Tekeche MongoDB has no replica set / failover (standalone on .53 since 09-13), and BIKODC's mongod
  is in a dead replica-set state - owner decision needed, separate HIGH CR if a fix is wanted.
- Class: HIGH (Get-ChangeRisk 11-16 ~16:35; Claude had written MEDIUM). Needs an approved window.
- Impact: none on users. mongodump of .53 reads ~11 MB.
- Rollback: `git revert` of the script commit.
- Checks after: New-RecoveryPoint -Description "CR-06 test" produces a non-empty db-dump; a forced bad URI makes it
  stop with an error; Test-Build (Tekeche) passes.
- Recovery point: the script being fixed cannot dump the DB, so: git state of ops/scripts (commit before the change)
  + the nightly Tekeche-MongoDB-Backup of 2026-11-16 01:00 (1.4 MB). The change does not write to MongoDB.
- Window (proposed): now, 30 minutes, after "approve CR-2026-11-16-06 window now".
- Approval: "approve CR-2026-11-16-06", then (after Get-ChangeRisk said HIGH) "approve CR-2026-11-16-06 window now"
  (owner, 11-16 ~16:28 UTC).
- Result: d59c11d. Test 1: recovery point 2026-11-16_16-29-56 = 26 collections / 10 MB from .53. Test 2: script copy
  with a 127.0.0.1 URI stops at the dump, exit 1, nothing reported created. Test 3: Test-Build 9/9. Set-KnownGood
  Build #64. Invoke-Rollback's restore now also fails loudly (not exercised - it would overwrite production).
  Note: the old password stays in git history of these scripts (rotation = owner decision). Done.

### CR-2026-11-16-05  NDP creator discovery: skip gambling/betting channels
- Requested by: Claude (11-16, after reviewing discovery job results).
- What changes: nouvellesdupays `apps/worker/src/creator-agents.js` `runDiscoverJob`: a new rejection reason
  `gambling` (added to REJECTIONS and the job log line), checked on channel title + handle + description with
  `/(1xbet|casino|betting|bookmaker|paris sportifs?|jackpot|\bslots\b|sportsbook)/i`. Plain "bet" is NOT matched
  (read-only check 11-16: it would wrongly catch candidate 113 "Beto Dias Official"). A unit test for both cases.
  Worker image rebuild (Kaniko, from GitHub main) + rollout, as earlier worker builds.
  Not in this CR: corporate brands (KFC, Pantene, Riyadh Air...) - no reliable rule; existing junk candidates stay
  as they are (rejecting them would be a separate CR, done in /admin/creators).
- Why: candidates 144 "TUNISIEN-CASINO STREAMER" and 524 "1XBET Philippines" were added by discovery; gambling
  channels must never reach the review queue. Queue on 11-16: 549 candidates, 136 without a country.
- Class: MEDIUM (feature change in a worker; Get-ChangeRisk to be run alone before apply).
- Impact / downtime: worker restart only (no reader-facing downtime); discovery adds slightly fewer candidates.
- Rollback: `rollout undo`/set image to the rollback tag of the current worker (f14f7de2) recorded before the build.
- Checks after: worker tests pass (CI pod); worker pod Running on the new digest; next discovery job's result shows a
  `gambling` count; Test-Build.
- Recovery point: New-RecoveryPoint before.
- Approval: "approve CR-2026-11-16-05" (owner, 11-16 ~15:30 UTC).
- Result: Get-ChangeRisk MEDIUM; NDP recovery point 2026-11-16_15-33-18 (full); commit f75946e pushed (ls-remote
  checked); worker tests 115/115; rollback tag rollback-f1869de6 (live worker was f1869de6, not f14f7de2 as noted
  earlier); job b263-worker -> a1952d25, new code checked in the image; worker run 29914080 Succeeded 16:00;
  Test-Build 8/8; Set-KnownGood (registry #262). Deviation: Claude first ran the Tekeche New-RecoveryPoint by mistake
  - it created a partial folder (its MongoDB dump produced nothing and the script crashed); no change resulted (see
  CR-06). Done. creator-agents 16:25 ran on a1952d25 (Succeeded) but YouTube quota was spent (75 units left, 10 jobs
  waiting), so the filter has not met a real job yet.

### CR-2026-11-16-03  Add 3 Côte d'Ivoire creator candidates
- Requested by: Claude, after owner "approve 2a" (11-16) and "go 3".
- What changes: 3 new rows in NDP `creators` (review_status **candidate**, country CI, not public) + their YouTube
  account in `social_accounts`, through the admin API in the owner's logged-in session (no direct SQL):
  - Le Samouraï Théa — UCLtc8gGTaQzo__2_MBRbT2g (@thearobert8642), channel registered MA, 293k subscribers
  - Franklin Nyamsi — UCiQxANAElvyi0LubPBit8xw (@franklinnyamsi), registered US, 494k
  - Bantu Media Authentique — UCy5RkD0TDvDMwDtQNBs3tpQ (@bantumediaauthentique2097), registered SN, 115k
  Each with a reviewer note: "Brief section 3 named creator for Côte d'Ivoire; YouTube channel registered <XX>, not
  CI - owner to decide". "État d'Urgence": no matching channel found, not added.
- Why: brief section 3 names them as initial CI candidates; the discovery agent refuses channels registered abroad.
- Class: HIGH (Get-ChangeRisk; similar approvals #254/#257 rated MEDIUM with other wording).
- Impact / downtime: none; candidates are never shown publicly. No approval of any creator in this CR.
- Rollback: mark the 3 creators rejected in /admin/creators (or delete the rows they created; ids recorded at apply).
- Checks after: GET /api/admin/creators shows them as candidates with the note; public /api/creators unchanged (22).
- Window: now, about 15 minutes, once the owner is logged in to /admin.
- Recovery point: New-RecoveryPoint before.
- Approval: "approve CR-2026-11-16-03" (owner, 11-16 ~13:00 UTC).
- Result: recovery point 2026-11-16_13-04-24; added through the admin API in the owner's session: 515
  le-samourai-thea (account 1696), 516 franklin-nyamsi (1697), 517 bantu-media-authentique (1698), all
  candidate / REQUIRES_REVIEW / CI / fr with the reviewer note; public /api/creators still 22, no CI creator. Done.

### CR-2026-11-16-02  dr-haproxy: check for and delete a leftover snapshot
- Requested by: Claude (owner asked to raise it, 11-16).
- What changes: ESXi VM dr-haproxy (vms/70, 192.168.1.50). Step 1 read-only: Manage snapshots, record what exists
  (name, date, size of delta). Step 2 only if a snapshot from 11-15 (~16:50 ESXi task clock) exists: Delete snapshot
  (ESXi merges the delta into the base disk; the VM keeps its current state).
- Why: dr-haproxy froze 11-14 and 11-16 (same signs: Tools not reporting, CPU 2.9 GHz, used space 5.96 -> 7.37 GB).
  A snapshot taken 11-15 then left in place grows a delta file and slows disk I/O; it is the main suspect.
- Class: HIGH (public entry point).
- Impact / downtime: none planned, but the merge is heavy disk I/O on a VM that freezes under I/O trouble: risk of
  a freeze during the merge = all public sites down until reset (as 11-14/11-16, ~15 min).
- Rollback: a deleted snapshot cannot be restored (the VM's current state is kept, only the old point in time is
  lost). If the VM freezes: ESXi Reset (EMERGENCY, section 5).
- Checks after: Recent tasks "Remove snapshot" completed; Manage snapshots empty; dr-haproxy answers; outside check of
  nouvellesdupays.com, tekeche.com, livbiko.com, 225woyo.com, kendebabi.com; NDP Test-Build; uptime-state "up".
- Window: a quiet hour (proposal: 03:00 UTC, 20 minutes), owner logged in to ESXi in the automated Chrome tab.
- Approval: needs "approve CR-2026-11-16-02 window <time>". Step 1 (read-only look) may happen any time.

### CR-2026-11-16-04  Approve 3 Côte d'Ivoire creators
- Requested by: owner decision 11-16 ("Approve all 3"), written up by Claude.
- What changes: creators 515 Le Samouraï Théa, 516 Franklin Nyamsi, 517 Bantu Media Authentique (CI): confidence
  REQUIRES_REVIEW -> PROVISIONAL, a reviewer-decision evidence row each (note "Décision du propriétaire 2026-11-16
  (CR-2026-11-16-04) - chaîne YouTube enregistrée hors CI"), review_status candidate -> approved. Through the admin
  API in the owner's session, as Builds #254/#257.
- Why: brief section 3 names them for Côte d'Ivoire; owner decided they count for CI although their channels are
  registered in MA / US / SN.
- Class: HIGH (Get-ChangeRisk; the same kind of approval was MEDIUM for #254/#257 with other wording). Window below.
- Impact: they become public at /creators/<slug> as "sélectionné par la rédaction (identité non vérifiée)"; CI goes
  to 3 approved (5 needed for /youtube/cote-divoire). Ranked at the next daily ranking run.
- Rollback: reverse.sql (back to candidate / REQUIRES_REVIEW, delete the 3 evidence rows), rehearsed before.
- Checks after: admin API shows approved/PROVISIONAL; public /api/creators 25 incl. 3 CI; profile pages 200; Test-Build.
- Window: now, 10 minutes (owner logged in to /admin).
- Approval: "approve CR-2026-11-16-04" (owner, 11-16 ~13:33 UTC).
- Result: recovery point 2026-11-16_13-35-38; 515/516/517 approved PROVISIONAL, evidence 38/39/40; public
  /api/creators 25 (3 CI), the 3 profile pages 200; Test-Build 8/8. Deviation: reverse.sql
  (nouvellesdupays ops/release-creators-approve-ci) was written and rehearsed AFTER the apply, not before as the CR
  said - rehearsal OK (3 rows each, rolled back). Done.
