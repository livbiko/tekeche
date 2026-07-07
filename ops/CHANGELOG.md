# Changelog

All notable changes to the Tekeche system are documented here.
Format: `[Date] [Risk] Change description — Who`

---

## 2026-06-28

- **[MEDIUM]** Increased OTP rate limit: 3→10 per minute (per-IP), 5→15 per 10min (per-identifier) — Rate limit was too strict, blocking testers from logging in
- **[LOW]** Relocated all test driver locations to Plateau, Abidjan for geospatial dispatch testing
- **[LOW]** Added invite script for kouadioboignyfelix@gmail.com
- **[LOW]** Cleared OTP rate limit blocks for all testers

## 2026-06-18

- **[HIGH]** HA setup complete — NLB VIP 192.168.1.100, ARR cross-server farm, MongoDB RS rs0, failover tested

## 2026-06-17

- **[HIGH]** Migrated MongoDB from Atlas M0 to on-premise MongoDB 8.3 — service=MongoDB, 127.0.0.1:27017, auth enabled

## 2026-06-14 (Booking Flow Fixes)

- **[MEDIUM]** Added KYC filter to ride pre-flight (`countDocuments` now checks `kycStatus`)
- **[MEDIUM]** Added startup driver availability reset (resets drivers stuck as unavailable with no active trip)
- **[LOW]** Added dispatch lifecycle logging (pool breakdown, channel selection, timeout outcomes)
- **[LOW]** Added local build config (`APP_ENV=local`, `.env.local`, network security XML)
- **[MEDIUM]** Fixed driver role in `/nearby` route (`protect(['user'])` → `protect(['passenger', 'driver'])`)
- **[HIGH]** Fixed SMTP port (Gmail port 587 STARTTLS for OTP email)
- **[HIGH]** Implemented MongoDB connection resilience (retry logic, graceful shutdown)
- **[HIGH]** Fixed IIS ARR dead server detection

## 2026-06-28 (SMS OTP)

- **[MEDIUM]** Brevo SMS activé dans le flux OTP — sendOTP passe maintenant le phone à sendSMS quand disponible
- **[LOW]** Auth controller passe le numéro de téléphone à sendOTP
- Canal de réponse : email, sms, ou email+sms selon disponibilité
- **En attente** : crédits SMS Brevo à acheter sur app.sendinblue.com/billing/addon/customize/sms
