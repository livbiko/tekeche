# FSMO Seizure Runbook

## Background

All 5 FSMO roles (Schema Master, Domain Naming Master, PDC Emulator, RID
Pool Manager, Infrastructure Master) currently sit on **BikoDC** alone
(confirmed 2026-07-12). Active Directory does not support automatic FSMO
failover — this is by design, not a gap. Seizing a role while the original
holder might still come back online risks USN rollback and metadata
corruption, so Microsoft's own guidance is that this stays a manual,
deliberate decision.

`Test-FSMOHealth.ps1` alerts when a FSMO holder becomes unreachable. This
runbook is what to do after that alert, if BikoDC is confirmed down.

**Shared forest warning**: this AD forest also hosts ALBANDC, GUIZODC,
PASCALEDC, JUMPBOX, and BIKORDP1 — systems unrelated to Tekeche. FSMO
seizure affects the whole forest/domain, not just Tekeche's systems. Treat
this as a forest-wide action, not a Tekeche-scoped one.

## Before you seize anything

1. **Confirm BikoDC is actually down, not just slow/partitioned.** Check:
   - Can you ping it from BOTH BikoDC1 and BikoDC2?
   - Is it reachable via the hypervisor console (VMware) directly, bypassing the network?
   - Is this a brief network blip (like the 2026-07-11 crash/reboot incident) rather than a real extended outage?
2. **Do not seize if there's any realistic chance BikoDC comes back within the hour.** A short outage is not worth the seizure risk — everything (AD auth, replication) keeps working via BikoDC1/BikoDC2 in the meantime; only PDC-Emulator-dependent operations (time sync authority, password changes propagating immediately, some Group Policy behavior) degrade slightly during that window, which is tolerable short-term.
3. If BikoDC is confirmed down for an extended period (hardware failure, extended outage, etc.), proceed below.

## Seizing the roles

Run from a healthy DC (BikoDC1 or BikoDC2), as Domain/Enterprise Admin:

```powershell
# Schema Master and Domain Naming Master require Enterprise Admin rights
Move-ADDirectoryServerOperationMasterRole -Identity "BikoDC1" -OperationMasterRole SchemaMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity "BikoDC1" -OperationMasterRole DomainNamingMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity "BikoDC1" -OperationMasterRole PDCEmulator -Force
Move-ADDirectoryServerOperationMasterRole -Identity "BikoDC1" -OperationMasterRole RIDMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity "BikoDC1" -OperationMasterRole InfrastructureMaster -Force
```

(Substitute `BikoDC2` if BikoDC1 is the healthier/preferred target. You
don't have to put all 5 on the same DC — splitting Schema/Domain Naming
Master onto one and the other 3 onto another is also valid — but keeping
them together is simpler to reason about for a 3-DC environment this size.)

Verify:

```powershell
netdom query fsmo
```

## After seizing: if BikoDC comes back later

**Do not let it silently rejoin believing it still holds FSMO roles.**
Before reconnecting it to the network:

1. Confirm via `netdom query fsmo` from another DC that BikoDC is no longer listed as holding any role.
2. If BikoDC's own local copy of AD still thinks it holds roles it no longer does (common after a seizure), this is expected — it will reconcile via replication once reconnected, but verify with `dcdiag /test:knowsofroleholders` on BikoDC after it's back.
3. Run a full `repadmin /replsummary` and `dcdiag /q` afterward to confirm no replication conflicts.
4. Consider whether BikoDC should be metadata-cleaned and rebuilt from scratch instead, if the original failure was hardware-related and its integrity is in doubt (`ntdsutil` metadata cleanup, then re-promote as a fresh DC) — this is the safer option if there's any doubt about what state BikoDC was in when it went down.

## Validation checklist after any seizure

- [ ] `netdom query fsmo` shows the new holder(s)
- [ ] `repadmin /replsummary` shows 0 failures across all DCs
- [ ] `dcdiag /q` clean on all DCs
- [ ] `curl https://api.tekeche.com/health` returns `{"status":"ok"}`
- [ ] Password change test (change a test account's password, confirm it propagates)
- [ ] Group Policy update test (`gpupdate /force` on a test client)
