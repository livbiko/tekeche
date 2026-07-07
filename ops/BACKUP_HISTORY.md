# Backup History

All recovery points created by `New-RecoveryPoint.ps1` are logged here.
Recovery points are stored in `recovery-points/` and are never overwritten.

---

## 2026-06-28 13:45:21 â€” Initial known-good state — booking flow working, OTP rate limit raised

- **ID**: 2026-06-28_13-45-17_initial-known-good-state-booking-flow-wo
- **Reason**: First recovery point — baseline before future changes
- **API commit**: a9bb2f85  (master)
- **Mobile commit**: 4bd03c37 (main)
- **Impact**: None
- **DB dump**: 495.8 KB
- **Files affected**: src/app.js
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-06-28_13-45-17_initial-known-good-state-booking-flow-wo"`


## 2026-06-28 17:43:15 â€” Before Brevo SMS activation

- **ID**: 2026-06-28_17-43-12_before-brevo-sms-activation
- **Reason**: Activating SMS OTP via Brevo to fix high abandonment rate on login
- **API commit**: a9bb2f85  (master)
- **Mobile commit**: 4bd03c37 (main)
- **Impact**: Medium — OTP delivery channel changes from email-only to email+SMS
- **DB dump**: 497.8 KB
- **Files affected**: .env, src/services/otp.service.js
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-06-28_17-43-12_before-brevo-sms-activation"`


## 2026-06-28 20:30:33 â€” Before: Woyo shared ride service implementation

- **ID**: 2026-06-28_20-30-32_before-woyo-shared-ride-service-implemen
- **Reason**: 
- **API commit**: d5e0adf5  (master)
- **Mobile commit**: 4bd03c37 (main)
- **Impact**: Low
- **DB dump**: 498 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-06-28_20-30-32_before-woyo-shared-ride-service-implemen"`


## 2026-06-28 22:55:33 â€” Before: Woyo quartiers Abidjan + Woyo groups

- **ID**: 2026-06-28_22-55-32_before-woyo-quartiers-abidjan-woyo-group
- **Reason**: 
- **API commit**: 02d2042f  (master)
- **Mobile commit**: aa740186 (main)
- **Impact**: Low
- **DB dump**: 499.4 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-06-28_22-55-32_before-woyo-quartiers-abidjan-woyo-group"`


## 2026-06-30 09:21:35 â€” Before: Auto GPS pool detection replacing manual shared ride option

- **ID**: 2026-06-30_09-21-28_before-auto-gps-pool-detection-replacing
- **Reason**: 
- **API commit**: 412afbea  (master)
- **Mobile commit**: d68f2c5b (main)
- **Impact**: Low
- **DB dump**: 503 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-06-30_09-21-28_before-auto-gps-pool-detection-replacing"`


## 2026-06-30 12:29:31 â€” Before: OTA pipeline fix — replacing eas update with expo export custom deploy

- **ID**: 2026-06-30_12-29-29_before-ota-pipeline-fix-replacing-eas-up
- **Reason**: 
- **API commit**: fc997e0b  (master)
- **Mobile commit**: aebbb7fd (main)
- **Impact**: Low
- **DB dump**: 503 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-06-30_12-29-29_before-ota-pipeline-fix-replacing-eas-up"`


## 2026-06-30 15:07:47 â€” Before: Activate Produits feature — new screen + API serviceType filter

- **ID**: 2026-06-30_15-07-45_before-activate-produits-feature-new-scr
- **Reason**: 
- **API commit**: 9e55b47d  (master)
- **Mobile commit**: e17daca1 (main)
- **Impact**: Low
- **DB dump**: 503.1 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-06-30_15-07-45_before-activate-produits-feature-new-scr"`


## 2026-07-01 13:13:52 â€” Before: Add GET /api/drivers/status endpoint + dynamic driver in booking flow test

- **ID**: 2026-07-01_13-13-51_before-add-get-api-drivers-status-endpoi
- **Reason**: 
- **API commit**: 6c442086  (master)
- **Mobile commit**: 3c359eae (main)
- **Impact**: Low
- **DB dump**: 503.1 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-01_13-13-51_before-add-get-api-drivers-status-endpoi"`


## 2026-07-02 08:55:43 â€” Before: SMS fallback dispatch, longer timeout, socket reconnect tuning

- **ID**: 2026-07-02_08-55-41_before-sms-fallback-dispatch-longer-time
- **Reason**: 
- **API commit**: c5236d5c  (master)
- **Mobile commit**: 33a32c06 (main)
- **Impact**: Low
- **DB dump**: 505.4 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-02_08-55-41_before-sms-fallback-dispatch-longer-time"`


## 2026-07-03 10:17:34 â€” Before: Promote Android passenger build versionCode 61 to production track (all users)

- **ID**: 2026-07-03_10-17-32_before-promote-android-passenger-build-v
- **Reason**: 
- **API commit**: 25d5cc21  (master)
- **Mobile commit**: 24976781 (main)
- **Impact**: Low
- **DB dump**: 506.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-03_10-17-32_before-promote-android-passenger-build-v"`


## 2026-07-03 13:32:13 â€” Before: Woyo GPS auto-zone, payment Wave/MTN/Especes, service icon size +20%, woyo car emoji

- **ID**: 2026-07-03_13-32-09_before-woyo-gps-auto-zone-payment-wave-m
- **Reason**: 
- **API commit**: 25d5cc21  (master)
- **Mobile commit**: 5da31bf1 (main)
- **Impact**: Low
- **DB dump**: 506.1 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-03_13-32-09_before-woyo-gps-auto-zone-payment-wave-m"`


## 2026-07-03 17:07:04 â€” Before: Add all Cote d'Ivoire cities to localites collection

- **ID**: 2026-07-03_17-07-00_before-add-all-cote-d-ivoire-cities-to-l
- **Reason**: 
- **API commit**: 25d5cc21  (master)
- **Mobile commit**: 5da31bf1 (main)
- **Impact**: Low
- **DB dump**: 507.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-03_17-07-00_before-add-all-cote-d-ivoire-cities-to-l"`


## 2026-07-03 17:14:29 â€” Before: UI changes - service icons +20%, woyo car icon, GPS zone detection, Wave/MTN/Especes payment

- **ID**: 2026-07-03_17-14-27_before-ui-changes-service-icons-20-woyo
- **Reason**: 
- **API commit**: 25d5cc21  (master)
- **Mobile commit**: 5da31bf1 (main)
- **Impact**: Low
- **DB dump**: 512 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-03_17-14-27_before-ui-changes-service-icons-20-woyo"`


## 2026-07-04 02:19:50 â€” Before: replace woyo localite chips with GPS auto-detect in service/[id].tsx

- **ID**: 2026-07-04_02-19-44_before-replace-woyo-localite-chips-with
- **Reason**: 
- **API commit**: 25d5cc21  (master)
- **Mobile commit**: db785966 (main)
- **Impact**: Low
- **DB dump**: 511.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-04_02-19-44_before-replace-woyo-localite-chips-with"`


## 2026-07-04 14:41:42 â€” Before: RRAS RemoteAccess role install + IKEv2 VPN S2S config for OCI tunnels 140.238.94.206 / 152.67.132.125

- **ID**: 2026-07-04_14-41-38_before-rras-remoteaccess-role-install-ik
- **Reason**: 
- **API commit**: 25d5cc21  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 512 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-04_14-41-38_before-rras-remoteaccess-role-install-ik"`

