# Change Register

One entry per change request (process: `CHANGE_APPROVAL.md`). Newest first. Status: requested / approved /
done / rolled back / rejected / EMERGENCY.

| CR | Title | Requested by | Class | Approved (owner's words, time UTC) | Window | Status |
|---|---|---|---|---|---|---|
| CR-2026-11-18-01 | NDP worker + API: channel statistics into channel_metrics, shown on cards; discovery topic map on active categories | Claude (follow-up of CR-2026-11-17-02/04) | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-18-01" 11-18 | 15:01-15:20 | deployed (NDP #269); first data run 11-19 07:25 to verify |
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
- Approval: needs "approve CR-2026-11-18-05" and "approve CR-2026-11-18-05 window <time>".
- Result:

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
- Approval: needs "approve CR-2026-11-16-10 window now".

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
