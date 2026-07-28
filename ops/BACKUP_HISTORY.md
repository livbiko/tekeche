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


## 2026-07-08 19:47:02 â€” Before BikoFW-SRX OCI VPN config apply

- **ID**: 2026-07-08_19-46-55_before-bikofw-srx-oci-vpn-config-apply
- **Reason**: Applying new site-to-site IPsec VPN (dmz zone, st0.1/st0.2) to BikoFW-SRX
- **API commit**: 25d5cc21  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low - additive only, no existing config removed
- **DB dump**: 514.5 KB
- **Files affected**: BikoFW-SRX Junos config: security zones dmz, ike/ipsec proposals+policies+gateways+vpns, interfaces st0.1/st0.2, security policies DMZ-TO-OCI/OCI-TO-DMZ, routing-options static route 10.0.0.0/16
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-08_19-46-55_before-bikofw-srx-oci-vpn-config-apply"`


## 2026-07-09 12:35:45 â€” Before switching alert.service.js to Brevo SMTP relay

- **ID**: 2026-07-09_12-35-39_before-switching-alert-service-js-to-bre
- **Reason**: User wants admin alerts sent via Brevo (noreply@tekeche.com) instead of raw Gmail SMTP
- **API commit**: 25d5cc21  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low-Medium - sender transport change only, recipient unchanged
- **DB dump**: 514.5 KB
- **Files affected**: tekeche-api/src/services/alert.service.js
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_12-35-39_before-switching-alert-service-js-to-bre"`


## 2026-07-09 13:37:53 â€” Before rebuilding BikoFW-SRX OCI VPN crypto to Oracle template defaults

- **ID**: 2026-07-09_13-37-49_before-rebuilding-bikofw-srx-oci-vpn-cry
- **Reason**: User requested full rebuild to match Oracle official SRX template (SHA-384/Group5/SHA1-96) plus DPD/vpn-monitor/df-bit-clear/MSS-clamp
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Medium - temporary drop of currently-working tunnel2 during crypto renegotiation, no production traffic depends on this VPN yet
- **DB dump**: 514.5 KB
- **Files affected**: ops/oci/vpn_srx_tunnels.tf, BikoFW-SRX Junos config: IKE/IPsec proposals+policies, VPN objects, security flow tcp-mss
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_13-37-49_before-rebuilding-bikofw-srx-oci-vpn-cry"`


## 2026-07-09 15:44:54 â€” Before adding static ARP entry on BikoFW-SRX for NLB VIP

- **ID**: 2026-07-09_15-44-50_before-adding-static-arp-entry-on-bikofw
- **Reason**: NLB VIP 192.168.1.100 unreachable via routed VPN traffic due to multicast MAC not resolvable through router ARP - causing OCI LB failover to under-provisioned standby, likely cause of multi-user login failures
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low - single additive static ARP entry, does not touch NLB cluster or existing routing/policies
- **DB dump**: 514.5 KB
- **Files affected**: BikoFW-SRX Junos config: interfaces irb unit 50 static ARP entry
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_15-44-50_before-adding-static-arp-entry-on-bikofw"`


## 2026-07-09 15:55:17 â€” Before switching TekecheCluster NLB from MULTICAST to UNICAST

- **ID**: 2026-07-09_15-55-13_before-switching-tekechecluster-nlb-from
- **Reason**: NLB multicast MAC not resolvable via router ARP, blocking OCI-routed traffic to primary VIP 192.168.1.100, causing full LB failover to under-provisioned OCI standby
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Medium - brief NLB reconvergence (~5-30s) on both nodes; currently zero live traffic through this VIP due to the existing bug, so practical impact is low right now
- **DB dump**: 514.5 KB
- **Files affected**: TekecheCluster NLB configuration (BikoDC, BikoDC1) - operation mode
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_15-55-13_before-switching-tekechecluster-nlb-from"`


## 2026-07-09 17:11:04 â€” Before rebooting BikoDC to clear stuck NLB Converging state

- **ID**: 2026-07-09_17-10-59_before-rebooting-bikodc-to-clear-stuck-n
- **Reason**: BikoDC stuck in NLB Converging status after failed MULTICAST->UNICAST switch (RPC error 0x800706BE); reboot to force clean NLB reconvergence
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Medium - full API downtime ~5-8 min during reboot, PM2 auto-resurrect verified working via boot scheduled task
- **DB dump**: 514.5 KB
- **Files affected**: BikoDC full reboot - PM2 processes, NLB driver state
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_17-10-59_before-rebooting-bikodc-to-clear-stuck-n"`


## 2026-07-09 20:08:42 â€” Before: Provision OKE cluster, node pool, OCIR in OCI (Phase 1 foundation)

- **ID**: 2026-07-09_20-08-33_before-provision-oke-cluster-node-pool-o
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 514.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_20-08-33_before-provision-oke-cluster-node-pool-o"`


## 2026-07-09 21:25:30 â€” Before: Fix BIKODC DNS self-registration (disable Ethernet1/Ethernet2 registration, clean stale A records)

- **ID**: 2026-07-09_21-25-26_before-fix-bikodc-dns-self-registration
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 514.6 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_21-25-26_before-fix-bikodc-dns-self-registration"`


## 2026-07-09 22:18:54 â€” Before: Reset local MongoDB admin password via standalone recovery mode (brief primary outage expected)

- **ID**: 2026-07-09_22-18-49_before-reset-local-mongodb-admin-passwor
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 514.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_22-18-49_before-reset-local-mongodb-admin-passwor"`


## 2026-07-09 22:30:01 â€” Before: MongoDB rs.reconfig() hostnames to IPs (BIKODC/BIKODC1 members)

- **ID**: 2026-07-09_22-29-56_before-mongodb-rs-reconfig-hostnames-to
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 514.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_22-29-56_before-mongodb-rs-reconfig-hostnames-to"`


## 2026-07-09 23:12:27 â€” Before: rs.remove 10.0.2.10 (dead OCI standby, non-voting member)

- **ID**: 2026-07-09_23-12-22_before-rs-remove-10-0-2-10-dead-oci-stan
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 514.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_23-12-22_before-rs-remove-10-0-2-10-dead-oci-stan"`


## 2026-07-09 23:21:21 â€” Before: insert synthetic test driver for booking-flow test

- **ID**: 2026-07-09_23-21-19_before-insert-synthetic-test-driver-for
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 514.6 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-09_23-21-19_before-insert-synthetic-test-driver-for"`


## 2026-07-10 08:00:34 â€” Before: add static route 10.0.0.0/16 via 192.168.1.1 on BIKODC (test on-prem network gap theory)

- **ID**: 2026-07-10_08-00-30_before-add-static-route-10-0-0-0-16-via
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 515 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-10_08-00-30_before-add-static-route-10-0-0-0-16-via"`


## 2026-07-10 08:04:39 â€” Before: add MongoDB firewall rule allowing OCI VCN (10.0.0.0/16)

- **ID**: 2026-07-10_08-04-37_before-add-mongodb-firewall-rule-allowin
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 515 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-10_08-04-37_before-add-mongodb-firewall-rule-allowin"`


## 2026-07-10 09:26:51 â€” Before: create acme.tekeche.com DNS zone for delegated ACME validation

- **ID**: 2026-07-10_09-26-47_before-create-acme-tekeche-com-dns-zone
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 515 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-10_09-26-47_before-create-acme-tekeche-com-dns-zone"`


## 2026-07-10 11:59:44 â€” Before: Re-issue Let's Encrypt cert for api/staging-api/security.tekeche.com via win-acme HTTP-01 + PemFiles store

- **ID**: 2026-07-10_11-59-41_before-re-issue-let-s-encrypt-cert-for-a
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 515 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-10_11-59-41_before-re-issue-let-s-encrypt-cert-for-a"`


## 2026-07-10 13:18:30 â€” Before: Add OCI LB port-80 backend set + repoint http-80 listener (fix plain-HTTP-to-HTTPS-port bug blocking ACME HTTP-01)

- **ID**: 2026-07-10_13-18-27_before-add-oci-lb-port-80-backend-set-re
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 515 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-10_13-18-27_before-add-oci-lb-port-80-backend-set-re"`


## 2026-07-10 19:11:41 â€” Before: Switch TekecheCluster NLB from MULTICAST to UNICAST (retry, RPC blocker now cleared)

- **ID**: 2026-07-10_19-11-35_before-switch-tekechecluster-nlb-from-mu
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.8 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-10_19-11-35_before-switch-tekechecluster-nlb-from-mu"`


## 2026-07-11 11:08:55 — Before: OKE Phase 3 Ingress+LB cutover (TLS secret, ingress-nginx, NSG rule, LB backend add)

- **ID**: 2026-07-11_11-08-49_before-oke-phase-3-ingress-lb-cutover-tl
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.8 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_11-08-49_before-oke-phase-3-ingress-lb-cutover-tl"`


## 2026-07-11 13:47:45 — Before: Revert BikoDC1 NLB operation mode Unicast->Multicast to release stuck unicast MAC

- **ID**: 2026-07-11_13-47-41_before-revert-bikodc1-nlb-operation-mode
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.8 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_13-47-41_before-revert-bikodc1-nlb-operation-mode"`


## 2026-07-11 14:34:30 — Before: Re-add BikoDC1 to Mongo rs0 as non-voting secondary (priority:0, votes:0)

- **ID**: 2026-07-11_14-34-27_before-re-add-bikodc1-to-mongo-rs0-as-no
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.9 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_14-34-27_before-re-add-bikodc1-to-mongo-rs0-as-no"`


## 2026-07-11 14:59:56 — Before: enable Bastion plugin + wipe/rejoin OCI standby Mongo + upgrade BikoDC1 to voting member

- **ID**: 2026-07-11_14-59-52_before-enable-bastion-plugin-wipe-rejoin
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.8 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_14-59-52_before-enable-bastion-plugin-wipe-rejoin"`


## 2026-07-11 15:11:00 — Before: reboot OCI standby VM to revive stuck Cloud Agent

- **ID**: 2026-07-11_15-10-57_before-reboot-oci-standby-vm-to-revive-s
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.8 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_15-10-57_before-reboot-oci-standby-vm-to-revive-s"`


## 2026-07-11 16:10:44 — Before: Redis replication fixes (OCI standby replicaof target, BikoDC local Memurai as 2nd replica)

- **ID**: 2026-07-11_16-10-39_before-redis-replication-fixes-oci-stand
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.8 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_16-10-39_before-redis-replication-fixes-oci-stand"`


## 2026-07-11 16:28:47 — Before: Deploy Redis Sentinel (OCI standby + 2 OKE pods) and Sentinel-aware tekeche-api code (OKE only)

- **ID**: 2026-07-11_16-28-43_before-deploy-redis-sentinel-oci-standby
- **Reason**: 
- **API commit**: 633e89de  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.9 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_16-28-43_before-deploy-redis-sentinel-oci-standby"`


## 2026-07-11 16:52:13 — Before: reboot OKE node oke-cphqhpzsmwq-nde2atnycdq-s2eunfqwwza-0 to revive stuck Cloud Agent for image build

- **ID**: 2026-07-11_16-52-10_before-reboot-oke-node-oke-cphqhpzsmwq-n
- **Reason**: 
- **API commit**: af78e1a4  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 519.8 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_16-52-10_before-reboot-oke-node-oke-cphqhpzsmwq-n"`


## 2026-07-11 19:09:29 — Before: Sentinel automatic failover test (stop BikoDC1 Memurai, confirm promotion, restore)

- **ID**: 2026-07-11_19-09-24_before-sentinel-automatic-failover-test
- **Reason**: 
- **API commit**: 60ad0a3f  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_19-09-24_before-sentinel-automatic-failover-test"`


## 2026-07-11 19:49:48 — Before: live BikoDC shutdown test (user-initiated) to validate Mongo/NLB failover to BikoDC1

- **ID**: 2026-07-11_19-49-44_before-live-bikodc-shutdown-test-user-in
- **Reason**: 
- **API commit**: 60ad0a3f  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_19-49-44_before-live-bikodc-shutdown-test-user-in"`


## 2026-07-11 20:45:50 — Before: restart KDC on BikoDC to clear stale Kerberos ticket cache post-crash

- **ID**: 2026-07-11_20-45-43_before-restart-kdc-on-bikodc-to-clear-st
- **Reason**: 
- **API commit**: 60ad0a3f  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_20-45-43_before-restart-kdc-on-bikodc-to-clear-st"`


## 2026-07-11 22:18:08 — Before: remove dead RRAS OCI-Tunnel1/2 S2S VPN interfaces on BikoDC (superseded by BikoFW-SRX VPN)

- **ID**: 2026-07-11_22-18-07_before-remove-dead-rras-oci-tunnel1-2-s2
- **Reason**: 
- **API commit**: 60ad0a3f  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.6 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-11_22-18-07_before-remove-dead-rras-oci-tunnel1-2-s2"`


## 2026-07-12 09:41:13 — Before: Add OCI boot-volume backup policy (bronze) for tekeche-standby VM

- **ID**: 2026-07-12_09-41-12_before-add-oci-boot-volume-backup-policy
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.6 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_09-41-12_before-add-oci-boot-volume-backup-policy"`


## 2026-07-12 09:51:10 — Before: Add OCI monitoring alarms (VPN/OKE-node/LB-backend) + notification topic

- **ID**: 2026-07-12_09-51-08_before-add-oci-monitoring-alarms-vpn-oke
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_09-51-08_before-add-oci-monitoring-alarms-vpn-oke"`


## 2026-07-12 13:35:15 — Before: Toggle BikoDC Ethernet0 adapter disable/enable to force upstream router ARP re-learn after stale-MAC issue broke inbound public traffic

- **ID**: 2026-07-12_13-35-10_before-toggle-bikodc-ethernet0-adapter-d
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_13-35-10_before-toggle-bikodc-ethernet0-adapter-d"`


## 2026-07-12 14:54:51 — Before: Fix SRX destination-NAT pool BDCSRV-POOL to point to 192.168.1.101 (BikoDC) instead of the unreachable NLB VIP 192.168.1.100, restoring public HTTPS access to Tekeche

- **ID**: 2026-07-12_14-54-49_before-fix-srx-destination-nat-pool-bdcs
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_14-54-49_before-fix-srx-destination-nat-pool-bdcs"`


## 2026-07-12 15:54:17 — Before: point OCI LB onprem backend at BikoDC direct IP (192.168.1.101) instead of broken NLB VIP (192.168.1.100)

- **ID**: 2026-07-12_15-54-10_before-point-oci-lb-onprem-backend-at-bi
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_15-54-10_before-point-oci-lb-onprem-backend-at-bi"`


## 2026-07-12 17:18:50 — Before: restart tekeche-api pm2 process on BikoDC1 (was crash-looping earlier today on missing ioredis, since fixed in shared node_modules, currently stopped)

- **ID**: 2026-07-12_17-18-47_before-restart-tekeche-api-pm2-process-o
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_17-18-47_before-restart-tekeche-api-pm2-process-o"`


## 2026-07-12 17:33:06 — Before: sync server.js/package.json/package-lock.json/web.config from BikoDC to BikoDC1 (stale independent copy) and npm install

- **ID**: 2026-07-12_17-33-04_before-sync-server-js-package-json-packa
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 520.5 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_17-33-04_before-sync-server-js-package-json-packa"`


## 2026-07-12 17:59:28 — Before: reinstall Node.js on BikoDC1 (v24.17.0 -> v20.18.0 to match BikoDC) and retry npm install

- **ID**: 2026-07-12_17-59-26_before-reinstall-node-js-on-bikodc1-v24
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_17-59-26_before-reinstall-node-js-on-bikodc1-v24"`


## 2026-07-12 18:31:54 — Before: register Scheduled Task on BikoDC1 to run pm2 resurrect at startup, independent of interactive session

- **ID**: 2026-07-12_18-31-52_before-register-scheduled-task-on-bikodc
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_18-31-52_before-register-scheduled-task-on-bikodc"`


## 2026-07-12 18:39:27 — Before: register Scheduled Task on BikoDC (production) to run pm2 resurrect at startup - registration only, not tested

- **ID**: 2026-07-12_18-39-25_before-register-scheduled-task-on-bikodc
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.3 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_18-39-25_before-register-scheduled-task-on-bikodc"`


## 2026-07-12 18:45:15 — Before: Phase 3 - reboot BikoDC to validate PM2 scheduled task auto-recovery

- **ID**: 2026-07-12_18-45-12_before-phase-3-reboot-bikodc-to-validate
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.3 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_18-45-12_before-phase-3-reboot-bikodc-to-validate"`


## 2026-07-12 21:58:30 — Before: Resize OCI standby VM to 8 OCPU/32GB and switch tekeche-api to PM2 cluster mode for full-capacity failover

- **ID**: 2026-07-12_21-58-25_before-resize-oci-standby-vm-to-8-ocpu-3
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_21-58-25_before-resize-oci-standby-vm-to-8-ocpu-3"`


## 2026-07-12 22:47:54 — Before: Failover drill - drain on-prem LB backend, route production traffic to resized OCI standby

- **ID**: 2026-07-12_22-47-52_before-failover-drill-drain-on-prem-lb-b
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_22-47-52_before-failover-drill-drain-on-prem-lb-b"`


## 2026-07-12 23:45:15 — Before: Phase A - deploy payment-gateway to OCI standby, fix hostname Mongo URI on production

- **ID**: 2026-07-12_23-45-13_before-phase-a-deploy-payment-gateway-to
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-12_23-45-13_before-phase-a-deploy-payment-gateway-to"`


## 2026-07-13 11:15:46 — Before: OKE full-failover resize (4 OCPU/32GB nodes, LB backend IP fix, HPA maxReplicas 6)

- **ID**: 2026-07-13_11-15-40_before-oke-full-failover-resize-4-ocpu-3
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-13_11-15-40_before-oke-full-failover-resize-4-ocpu-3"`


## 2026-07-13 12:49:50 — Before: clean stale Memurai temp-rdb files and restart the crashed service

- **ID**: 2026-07-13_12-49-48_before-clean-stale-memurai-temp-rdb-file
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.3 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-13_12-49-48_before-clean-stale-memurai-temp-rdb-file"`


## 2026-07-13 16:11:30 — Before: Replace Memurai with native Redis 8.8.0 on BikoDC1

- **ID**: 2026-07-13_16-11-28_before-replace-memurai-with-native-redis
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-13_16-11-28_before-replace-memurai-with-native-redis"`


## 2026-07-13 16:31:43 — Before: Replace Memurai with native Redis 8.8.0 on BikoDC (primary)

- **ID**: 2026-07-13_16-31-41_before-replace-memurai-with-native-redis
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.3 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-13_16-31-41_before-replace-memurai-with-native-redis"`


## 2026-07-13 19:09:01 — Before: real BikoDC power-off failover test

- **ID**: 2026-07-13_19-08-59_before-real-bikodc-power-off-failover-te
- **Reason**: User powered off BikoDC for real (not a drain drill) to validate OCI standby/OKE failover under a genuine primary-outage scenario.
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: None (infrastructure/OS-level test, no code changes)
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-13_19-08-59_before-real-bikodc-power-off-failover-te"`
- **Outcome**: See `MAINTENANCE_LOG.md` 2026-07-13 19:09-19:23 entry. ~8-9min real downtime; OCI LB detected the outage after a ~3min lag then correctly marked the backend unhealthy for ~5min; PM2 came back up fully automatically (`PM2-TekecheAPI` task, confirmed via daemon log + zero logon events, no manual step) by 19:23:37; whether backup backends actually served traffic during the detection window is unverified/open.


## 2026-07-13 22:39:27 — Before: Disable redundant legacy Tekeche-PM2-Startup scheduled task on BikoDC

- **ID**: 2026-07-13_22-39-22_before-disable-redundant-legacy-tekeche
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-13_22-39-22_before-disable-redundant-legacy-tekeche"`


## 2026-07-13 22:49:13 — Before: fix missing SystemRoot registry value causing BikoDC System State backup failure

- **ID**: 2026-07-13_22-49-11_before-fix-missing-systemroot-registry-v
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.3 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-13_22-49-11_before-fix-missing-systemroot-registry-v"`


## 2026-07-13 23:12:22 — Before: Provision dedicated OCI RODC VM in tekeche-private-subnet for AD authentication resilience

- **ID**: 2026-07-13_23-12-20_before-provision-dedicated-oci-rodc-vm-i
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-13_23-12-20_before-provision-dedicated-oci-rodc-vm-i"`


## 2026-07-14 17:52:34 — Before: Remove stray DNS A-records 192.168.1.110 and 192.168.1.100 (NLB VIP) from bikodc and bikodc1

- **ID**: 2026-07-14_17-52-30_before-remove-stray-dns-a-records-192-16
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-14_17-52-30_before-remove-stray-dns-a-records-192-16"`


## 2026-07-14 22:11:45 — Before: AD Phase D - domain-join standby VM to livbiko.local via sssd/realmd

- **ID**: 2026-07-14_22-11-43_before-ad-phase-d-domain-join-standby-vm
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-14_22-11-43_before-ad-phase-d-domain-join-standby-vm"`


## 2026-07-16 10:20:22 — Before: extend BIKODC C: partition into existing unallocated ~50GB disk space

- **ID**: 2026-07-16_10-20-20_before-extend-bikodc-c-partition-into-ex
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-16_10-20-20_before-extend-bikodc-c-partition-into-ex"`


## 2026-07-16 11:43:31 — Before: add PM2-HealthMonitor scheduled task on BikoDC (mid-session crash detection)

- **ID**: 2026-07-16_11-43-29_before-add-pm2-healthmonitor-scheduled-t
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-16_11-43-29_before-add-pm2-healthmonitor-scheduled-t"`


## 2026-07-16 11:56:23 — Before: Add PM2-HealthMonitor scheduled task to BikoDC1

- **ID**: 2026-07-16_11-56-21_before-add-pm2-healthmonitor-scheduled-t
- **Reason**: Close mid-session PM2 crash monitoring gap on BikoDC1, mirroring the fix just validated on BikoDC
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low - new scheduled task only, no changes to running app process
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-16_11-56-21_before-add-pm2-healthmonitor-scheduled-t"`


## 2026-07-16 13:34:27 — Before: Consolidate 4 redundant tekeche-api startup mechanisms on BikoDC1

- **ID**: 2026-07-16_13-34-25_before-consolidate-4-redundant-tekeche-a
- **Reason**: Found 4 uncoordinated startup paths (2 scheduled tasks, 1 raw-CLI task, 1 dormant NSSM service) causing an unexplained hourly graceful reload; currently-live process runs under an undocumented SYSTEM-home PM2 daemon bypassing ecosystem.config.js (no max_memory_restart protection)
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Medium - changes which mechanism starts tekeche-api on BikoDC1 boot; app itself unaffected while running, but next reboot/restart must succeed via the new canonical path
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-16_13-34-25_before-consolidate-4-redundant-tekeche-a"`


## 2026-07-16 15:58:06 — Before: Supervised livbiko-OCI failover test

- **ID**: 2026-07-16_15-58-04_before-supervised-livbiko-oci-failover-t
- **Reason**: Verify OCI standby (and OKE backup backends) actually serve correct production traffic when BikoDC is taken out of LB rotation
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Medium - temporarily shifts all production traffic to backup backends (OCI standby + OKE); BikoDC app itself untouched, LB-routing-level test only
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-16_15-58-04_before-supervised-livbiko-oci-failover-t"`


## 2026-07-16 17:05:30 — Before: Isolation test of each OCI LB backup backend individually

- **ID**: 2026-07-16_17-05-28_before-isolation-test-of-each-oci-lb-bac
- **Reason**: Isolate which specific backend among {OCI standby, OKE node 1, OKE node 2} caused the 35% failure rate in the earlier failover test; VPN tunnel now confirmed UP (unlike during the earlier test)
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Medium - brief, surgical production traffic exposure to one isolated backup backend at a time, few seconds each, immediate rollback after each
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-16_17-05-28_before-isolation-test-of-each-oci-lb-bac"`


## 2026-07-16 18:37:50 — Before: Install real Let's Encrypt cert on OCI standby nginx (was self-signed)

- **ID**: 2026-07-16_18-37-48_before-install-real-let-s-encrypt-cert-o
- **Reason**: Root-caused the failover test's 35% failure rate to OCI standby serving a self-signed TLS cert; installing the already-issued real api.tekeche.com cert from BikoDC's win-acme store
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low - standby doesn't serve real traffic in steady state; nginx -t validates config before reload
- **DB dump**: 521.2 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-16_18-37-48_before-install-real-let-s-encrypt-cert-o"`


## 2026-07-17 02:05:43 — Before: Move tekeche-vcn/IGW/public-subnet/LB from tekeche-pub into UK compartment

- **ID**: 2026-07-17_02-05-40_before-move-tekeche-vcn-igw-public-subne
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-17_02-05-40_before-move-tekeche-vcn-igw-public-subne"`


## 2026-07-17 09:33:00 — Before: Delete 37 orphaned sz-probe test VCNs from tekeche-pub

- **ID**: 2026-07-17_09-32-58_before-delete-37-orphaned-sz-probe-test
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-17_09-32-58_before-delete-37-orphaned-sz-probe-test"`


## 2026-07-17 13:01:52 — Before: rebuild deleted production LB as Network Load Balancer

- **ID**: 2026-07-17_13-01-50_before-rebuild-deleted-production-lb-as
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-17_13-01-50_before-rebuild-deleted-production-lb-as"`


## 2026-07-17 19:53:54 — Before: fix false-positive OKE node-down alarm query

- **ID**: 2026-07-17_19-53-52_before-fix-false-positive-oke-node-down
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-17_19-53-52_before-fix-false-positive-oke-node-down"`


## 2026-07-17 21:52:27 — Before: tekeche-nlb failover drill (drain on-prem, verify standby, restore)

- **ID**: 2026-07-17_21-52-24_before-tekeche-nlb-failover-drill-drain
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-17_21-52-24_before-tekeche-nlb-failover-drill-drain"`


## 2026-07-18 00:04:04 — Before: tekeche-nlb standby drill re-test (drain on-prem, verify standby, restore)

- **ID**: 2026-07-18_00-04-02_before-tekeche-nlb-standby-drill-re-test
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-18_00-04-02_before-tekeche-nlb-standby-drill-re-test"`


## 2026-07-18 00:12:02 — Before: BikoDC1 route fix - 10.0.0.0/16 via SRX not via BikoDC

- **ID**: 2026-07-18_00-12-00_before-bikodc1-route-fix-10-0-0-0-16-via
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523.1 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-18_00-12-00_before-bikodc1-route-fix-10-0-0-0-16-via"`


## 2026-07-18 08:32:35 — Before: tekeche.com registrar NS cutover to OCI DNS

- **ID**: 2026-07-18_08-32-32_before-tekeche-com-registrar-ns-cutover
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-18_08-32-32_before-tekeche-com-registrar-ns-cutover"`


## 2026-07-18 12:17:41 — Before: rename TEKECHE-RODC to BIKOOCIDC2, cleanup orphaned metadata, re-promote as writable DC

- **ID**: 2026-07-18_12-17-36_before-rename-tekeche-rodc-to-bikoocidc2
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-18_12-17-36_before-rename-tekeche-rodc-to-bikoocidc2"`


## 2026-07-18 21:11:38 — Before: BIKOOCIDC2 investigation + orphaned AD metadata cleanup

- **ID**: 2026-07-18_21-11-34_before-bikoocidc2-investigation-orphaned
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-18_21-11-34_before-bikoocidc2-investigation-orphaned"`


## 2026-07-19 08:24:08 — Before: fix BikoDC/BikoDC1 DNS self-registration polluting DC identity records (register=PRIMARY)

- **ID**: 2026-07-19_08-24-06_before-fix-bikodc-bikodc1-dns-self-regis
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_08-24-06_before-fix-bikodc-bikodc1-dns-self-regis"`


## 2026-07-19 09:23:19 — Before: remove dead .100/.110 VIP IP bindings from BikoDC/BikoDC1 Ethernet0

- **ID**: 2026-07-19_09-23-17_before-remove-dead-100-110-vip-ip-bindin
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_09-23-17_before-remove-dead-100-110-vip-ip-bindin"`


## 2026-07-19 09:37:29 — Before: livbiko.com registrar NS cutover to OCI DNS

- **ID**: 2026-07-19_09-37-27_before-livbiko-com-registrar-ns-cutover
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_09-37-27_before-livbiko-com-registrar-ns-cutover"`


## 2026-07-19 09:56:50 — Before: repoint local split-horizon kendebabi.com/tekeche.com DNS zones from dead .100 VIP to .101

- **ID**: 2026-07-19_09-56-48_before-repoint-local-split-horizon-kende
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523.1 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_09-56-48_before-repoint-local-split-horizon-kende"`


## 2026-07-19 10:47:51 — Before: add 10.0.0.0/16 route via SRX on BikoDC2 (matches BikoDC/BikoDC1 fix)

- **ID**: 2026-07-19_10-47-48_before-add-10-0-0-0-16-route-via-srx-on
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_10-47-48_before-add-10-0-0-0-16-route-via-srx-on"`


## 2026-07-19 11:21:07 — Before: OCI/on-prem failover drain drill (re-verify after todays AD/DNS/network changes)

- **ID**: 2026-07-19_11-21-05_before-oci-on-prem-failover-drain-drill
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_11-21-05_before-oci-on-prem-failover-drain-drill"`


## 2026-07-19 12:38:40 — Before: add MongoDB - Allow OCI VCN firewall rule on BikoDC1 (fixes standby-to-BikoDC1 connectivity gap)

- **ID**: 2026-07-19_12-38-38_before-add-mongodb-allow-oci-vcn-firewal
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_12-38-38_before-add-mongodb-allow-oci-vcn-firewal"`


## 2026-07-19 15:00:55 — Before: kendebabi.com registrar NS cutover to OCI DNS

- **ID**: 2026-07-19_15-00-53_before-kendebabi-com-registrar-ns-cutove
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523.1 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_15-00-53_before-kendebabi-com-registrar-ns-cutove"`


## 2026-07-19 15:09:55 — Before: verify standby serves security.tekeche.com /security/* route (drain test)

- **ID**: 2026-07-19_15-09-53_before-verify-standby-serves-security-te
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_15-09-53_before-verify-standby-serves-security-te"`


## 2026-07-19 15:37:50 — Before: verify standby serves staging-api.tekeche.com (drain test)

- **ID**: 2026-07-19_15-37-48_before-verify-standby-serves-staging-api
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_15-37-48_before-verify-standby-serves-staging-api"`


## 2026-07-19 16:12:30 — Before: comprehensive failover drain test across all 5 domains after todays session

- **ID**: 2026-07-19_16-12-28_before-comprehensive-failover-drain-test
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_16-12-28_before-comprehensive-failover-drain-test"`


## 2026-07-19 16:28:25 — Before: create Standby-KendebabiSync scheduled task for kendebabi.com uploads sync

- **ID**: 2026-07-19_16-28-23_before-create-standby-kendebabisync-sche
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_16-28-23_before-create-standby-kendebabisync-sche"`


## 2026-07-19 16:57:19 — Before: extend dedicated IIS app pools to remaining 6 sites sharing DefaultAppPool

- **ID**: 2026-07-19_16-57-17_before-extend-dedicated-iis-app-pools-to
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523.1 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-19_16-57-17_before-extend-dedicated-iis-app-pools-to"`


## 2026-07-20 17:39:53 — Before deploy Palo Alto VM-Series Bundle1 PAYGO in new isolated livbiko-pa-vcn with VTAP mirroring

- **ID**: 2026-07-20_17-39-51_before-deploy-palo-alto-vm-series-bundle
- **Reason**: User approved OCI Marketplace PA VM-Series deployment for passive traffic monitoring, isolated VCN, zero blast radius on existing resources
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low - new isolated resources only, no existing infra touched
- **DB dump**: 523 KB
- **Files affected**: ops/oci/livbiko_pa_vcn.tf (new)
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-20_17-39-51_before-deploy-palo-alto-vm-series-bundle"`


## 2026-07-20 20:29:39 — Before live drain test of BikoDC-OCI failover (user-requested fresh drill)

- **ID**: 2026-07-20_20-29-36_before-live-drain-test-of-bikodc-oci-fai
- **Reason**: User requested a fresh live failover verification after tonight's isolated Palo Alto VCN build, to confirm nothing regressed the existing api.tekeche.com failover path
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low - same drain/verify/restore pattern proven clean in every prior drill, briefly routes real traffic through OCI standby
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-20_20-29-36_before-live-drain-test-of-bikodc-oci-fai"`


## 2026-07-21 08:58:24 — Before: retry livbiko_pa VTAP terraform apply diagnostic

- **ID**: 2026-07-21_08-58-21_before-retry-livbiko-pa-vtap-terraform-a
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-21_08-58-21_before-retry-livbiko-pa-vtap-terraform-a"`


## 2026-07-21 15:15:12 — Before: Run DISM StartComponentCleanup on BikoDC1 to reclaim WinSxS space on C:

- **ID**: 2026-07-21_15-15-10_before-run-dism-startcomponentcleanup-on
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-21_15-15-10_before-run-dism-startcomponentcleanup-on"`


## 2026-07-22 16:28:25 — Before: Add explicit 'manage capture-filters' IAM policy grant for Administrators in livbiko-pa compartment, retry VTAP creation

- **ID**: 2026-07-22_16-28-23_before-add-explicit-manage-capture-filte
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-22_16-28-23_before-add-explicit-manage-capture-filte"`


## 2026-07-24 16:40:07 — Before: Add Woyo as a third app variant in tekeche-mobile (branding, region-aware landing screen, EAS profiles)

- **ID**: 2026-07-24_16-40-05_before-add-woyo-as-a-third-app-variant-i
- **Reason**: 
- **API commit**: 8ccc9960  (master)
- **Mobile commit**: 564ebbc6 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-24_16-40-05_before-add-woyo-as-a-third-app-variant-i"`


## 2026-07-24 17:08:17 — Before: Set WOYO_APP_TOKEN environment variable in tekeche-api's .env

- **ID**: 2026-07-24_17-08-12_before-set-woyo-app-token-environment-va
- **Reason**: 
- **API commit**: 0d99efac  (master)
- **Mobile commit**: eb04db9c (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-24_17-08-12_before-set-woyo-app-token-environment-va"`


## 2026-07-25 03:06:02 — Before: Reboot BikoDC to activate Windows Hypervisor Platform for Android emulator acceleration

- **ID**: 2026-07-25_03-06-01_before-reboot-bikodc-to-activate-windows
- **Reason**: 
- **API commit**: 0d99efac  (master)
- **Mobile commit**: 0eb6bed9 (main)
- **Impact**: Low
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-25_03-06-01_before-reboot-bikodc-to-activate-windows"`


## 2026-07-25 17:58:20 — Before NouvellesDuPays OKE deploy + LB/DNS wiring

- **ID**: 2026-07-25_17-58-17_before-nouvellesdupays-oke-deploy-lb-dns
- **Reason**: New app going live on shared OKE cluster + OCI LB
- **API commit**: 0d99efac  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Medium (new namespace, additive LB/DNS changes only)
- **DB dump**: 523 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-25_17-58-17_before-nouvellesdupays-oke-deploy-lb-dns"`


## 2026-07-28 13:00:33 — Before: Add isSynthetic flag to Driver/Booking models and partition dispatch matching for 20-day bot simulation

- **ID**: 2026-07-28_13-00-29_before-add-issynthetic-flag-to-driver-bo
- **Reason**: 
- **API commit**: 0d99efac  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Low
- **DB dump**: 546.7 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-28_13-00-29_before-add-issynthetic-flag-to-driver-bo"`


## 2026-07-28 13:19:11 — Before: Fix ANSI-escape-code false positive in Test-Build.ps1 PM2 status check

- **ID**: 2026-07-28_13-19-10_before-fix-ansi-escape-code-false-positi
- **Reason**: 
- **API commit**: 0d99efac  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Low
- **DB dump**: 546.7 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-28_13-19-10_before-fix-ansi-escape-code-false-positi"`


## 2026-07-28 13:40:14 — Before: Add isSynthetic exclusion to admin.controller.js driver lists and stats endpoints

- **ID**: 2026-07-28_13-40-12_before-add-issynthetic-exclusion-to-admi
- **Reason**: 
- **API commit**: cbb30f57  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Low
- **DB dump**: 547 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-28_13-40-12_before-add-issynthetic-exclusion-to-admi"`


## 2026-07-28 13:48:32 — Before: Provision 35 synthetic bot User+Driver identity pairs on production for the 20-day QA fleet

- **ID**: 2026-07-28_13-48-30_before-provision-35-synthetic-bot-user-d
- **Reason**: 
- **API commit**: a586b5c1  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Low
- **DB dump**: 547 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-28_13-48-30_before-provision-35-synthetic-bot-user-d"`


## 2026-07-28 14:26:11 — Before: Add 20-day window scheduler that starts/stops bot fleet driver and passenger processes on production

- **ID**: 2026-07-28_14-26-09_before-add-20-day-window-scheduler-that
- **Reason**: 
- **API commit**: a586b5c1  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Low
- **DB dump**: 574 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-28_14-26-09_before-add-20-day-window-scheduler-that"`


## 2026-07-28 14:35:08 — Before: Deploy the bot QA fleet scheduler as a PM2-managed process on BikoDC

- **ID**: 2026-07-28_14-35-07_before-deploy-the-bot-qa-fleet-scheduler
- **Reason**: 
- **API commit**: a586b5c1  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Low
- **DB dump**: 574.8 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-28_14-35-07_before-deploy-the-bot-qa-fleet-scheduler"`


## 2026-07-28 14:53:16 — Before: Add orphaned-trip recovery to driver-bot.js and redeploy the live 20-day fleet

- **ID**: 2026-07-28_14-53-14_before-add-orphaned-trip-recovery-to-dri
- **Reason**: 
- **API commit**: a586b5c1  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Low
- **DB dump**: 575.9 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-28_14-53-14_before-add-orphaned-trip-recovery-to-dri"`


## 2026-07-28 15:37:47 — Before: Add periodic orphaned-trip sweep to scheduler.js and redeploy the live 20-day fleet

- **ID**: 2026-07-28_15-37-45_before-add-periodic-orphaned-trip-sweep
- **Reason**: 
- **API commit**: a586b5c1  (master)
- **Mobile commit**: dd0df115 (main)
- **Impact**: Low
- **DB dump**: 583.4 KB
- **Files affected**: 
- **Rollback**: `.\Invoke-Rollback.ps1 -PointId "2026-07-28_15-37-45_before-add-periodic-orphaned-trip-sweep"`

