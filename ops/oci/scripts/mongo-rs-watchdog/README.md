# mongo-rs-watchdog

Evicts `192.168.1.101:27017` / `192.168.1.102:27017` (BikoDC / BikoDC1) from
rs0's config once unreachable for 2 minutes, re-adds them once reachable
again for 1 minute. See the comment block at the top of `watchdog.js` for why.

Never touches arbiters or the OCI standby itself. Deployed on the OCI standby
(`10.0.2.10`) since it's the node most likely to be up and primary during an
on-prem outage.

## Deploy

Deployed 2026-08-01 to the OCI standby (`10.0.2.10`), systemd-managed, `enabled` +
`active`. See `ops/MAINTENANCE_LOG.md`'s 2026-08-01 19:xx entry for the full story,
including a real bootstrap-race bug found and understood (not yet re-drilled) before
this was considered done.

Steps, for reference / redeploying elsewhere:

1. On rs0's current primary, create the dedicated admin user (see `.env.example`
   for the exact command -- needs `clusterManager`, deliberately not reusing
   tekeche-api's app-scoped user). **Verify the user has actually replicated to
   the OCI-side members (standby + secondaries) before relying on it** -- creating
   it and immediately testing during an on-prem outage races replication; this bit
   us on first deploy (`UserNotFound` on the standby for ~2.5h until on-prem
   reconnected and the write caught up).
2. `scp` this directory to `/opt/mongo-rs-watchdog` on the standby, `npm install --omit=dev`.
3. Copy `.env.example` to `.env`, fill in the real password.
4. `cp mongo-rs-watchdog.service /etc/systemd/system/`, `systemctl daemon-reload`,
   `systemctl enable --now mongo-rs-watchdog`.
5. `journalctl -u mongo-rs-watchdog -f` to confirm it's polling both hosts as reachable
   AND that `replSetGetStatus` reads are succeeding (no `Authentication failed`/
   `UserNotFound` errors) -- a healthy-looking `active (running)` service can still be
   fully blind if step 1's user hasn't replicated yet.

## Kill switch

`touch /opt/mongo-rs-watchdog/DISABLED` -- watchdog keeps logging probe
results but stops taking any reconfig action. Remove the file to resume.

## Rollback

`systemctl stop mongo-rs-watchdog` (or delete the kill-switch-guarded unit
entirely) stops all future action. It does not undo a reconfig it already
made -- if a member was wrongly evicted, re-add it manually via
`rs.add(<original member config from state.json's savedMemberConfig>)`.
`state.json` keeps the exact original member config for both watched hosts
once first observed, specifically so a manual restore doesn't require
guessing priority/votes/tags.
