# Tekeche Release Risk Assessment & Impact Analysis

Run this checklist before every build submission. A release is only cleared when
all CRITICAL items are GREEN and all HIGH items have an accepted mitigation.

---

## 1. Change Classification

| Question | Answer |
|----------|--------|
| What files changed? | `git diff --stat main` |
| Is this JS-only? | If yes → use `eas update` (OTA), skip Play Store build |
| Does it touch native code / packages / permissions? | If yes → full build required |
| API-only change? | If yes → staging deploy first |

---

## 2. Authentication & OTP Impact ⚠️ CRITICAL

| Check | Status |
|-------|--------|
| OTP send flow still works (phone + email → receives code) | ☐ |
| OTP verify flow still works (correct code → logged in) | ☐ |
| Email fallback still triggers when SMS fails | ☐ |
| BLOCKED_EMAILS list unchanged or reviewed | ☐ |
| Per-identifier rate limiter not tightened to block real users | ☐ |
| Driver login still works (email-only, phone auto-saved) | ☐ |

**Test:** `POST /api/auth/send-otp { phone, email, role }` → expect 200 + code in inbox

---

## 3. API Stability ⚠️ CRITICAL

| Check | Status |
|-------|--------|
| `GET /health` returns 200 after deploy | ☐ |
| No new unhandled exceptions in `pm2 logs` | ☐ |
| MongoDB connection stable | ☐ |
| Staged on `staging-api.tekeche.com` first | ☐ |
| Deployed with `pm2 reload` (not `pm2 restart`) | ☐ |

---

## 4. Mobile App Impact — Passenger

| Check | Status |
|-------|--------|
| Login screen works (phone + email → OTP → logged in) | ☐ |
| Destination search / autocomplete returns suggestions | ☐ |
| Fare estimate works for all 4 vehicle types | ☐ |
| Book ride flow completes without crash | ☐ |
| Wallet balance loads | ☐ |
| Paystack top-up opens payment page | ☐ |
| Active trip tracking / driver location visible | ☐ |
| Receipt shown after trip completes | ☐ |

---

## 5. Mobile App Impact — Driver

| Check | Status |
|-------|--------|
| Login works (phone + email → OTP → logged in) | ☐ |
| Go online / go offline toggles correctly | ☐ |
| Ride request notification received | ☐ |
| Accept / reject ride works | ☐ |
| KYC screen loads all document types | ☐ |
| Earnings screen loads | ☐ |

---

## 6. Security Impact

| Check | Status |
|-------|--------|
| No new endpoint exposed without `protect()` middleware | ☐ |
| No user input passed raw to MongoDB queries | ☐ |
| No secrets or keys added to source code | ☐ |
| BLOCKED_EMAILS / BLOCKED_PHONES still active | ☐ |
| Per-identifier OTP rate limiter still in place | ☐ |

---

## 7. Data Impact

| Check | Status |
|-------|--------|
| No schema field removed that existing records depend on | ☐ |
| No breaking DB index changes without migration | ☐ |
| Existing user accounts unaffected (phone, email, wallet, trips) | ☐ |
| Driver accounts (KYC status, earnings) unaffected | ☐ |

---

## 8. Rollback Plan

| Item | Detail |
|------|--------|
| API rollback | `git checkout <prev-commit> -- src/` then `pm2 reload tekeche-api` |
| OTA rollback | `eas update --channel production --rollout 0` (pins previous update) |
| Play Store rollback | Google Play Console → Release → Halt rollout |
| DB rollback | Restore from MongoDB Atlas snapshot (daily) |
| Previous good tag | `git checkout 31-05-2026-goods-config` |

---

## 9. Risk Rating

| Rating | Criteria |
|--------|----------|
| 🟢 LOW | JS-only cosmetic change, no auth/payment/DB touch |
| 🟡 MEDIUM | New feature, new API endpoint, DB schema addition |
| 🔴 HIGH | Auth flow change, payment change, DB index/field removal |
| 🚨 CRITICAL | Any change to OTP, JWT, wallet deduction, user deletion |

**Current release risk:** ___________

---

## 10. Sign-off

| Step | Done |
|------|------|
| Risk assessment completed | ☐ |
| Staged and tested on staging API | ☐ |
| Authorized by: Assale Herve Kouame | ☐ |
| Build submitted to Play Store | ☐ |
| Testers notified | ☐ |
