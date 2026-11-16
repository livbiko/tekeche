# Change Register

One entry per change request (process: `CHANGE_APPROVAL.md`). Newest first. Status: requested / approved /
done / rolled back / rejected / EMERGENCY.

| CR | Title | Requested by | Class | Approved (owner's words, time UTC) | Window | Status |
|---|---|---|---|---|---|---|
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
