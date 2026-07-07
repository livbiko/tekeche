# Tekeche — High-Level Design (HLD)
## Meraki MX68 ↔ Oracle Cloud Infrastructure Site-to-Site VPN

**Version:** 1.0
**Date:** 2026-07-07
**Author:** Tekeche Engineering
**Status:** 🔴 BLOCKED — pending Meraki TAC response (support case filed 2026-07-06)
**Reference:** `ops/oci/HLD.md` (primary hybrid infra HLD), `ops/oci/LLD-MX68-VPN.md`, `ops/oci/Implementation-Plan-MX68-VPN.md`

---

## 1. Overview

Livbiko HQ's site network has two independent segments behind a single shared public IP (`81.130.238.41`):

- `192.168.1.0/24` — hosts BIKODC (the on-prem production NLB VIP), already reaching OCI over a working RRAS-managed IPSec tunnel (`tekeche-ipsec`, see main HLD).
- `192.168.128.0/24` — the Meraki MX68's own LAN, sitting behind BikoFW-SRX (a Juniper SRX300), with **no existing path to OCI**.

This project adds a **second, independent** site-to-site IPSec VPN connecting the MX68's LAN directly to OCI's private network (`10.0.0.0/16`), so devices on `192.168.128.0/24` can reach OCI-hosted services without being routed through BIKODC or RRAS.

**Goals**
- Give `192.168.128.0/24` direct, resilient reachability to the whole OCI private network
- Keep this fully isolated from the existing RRAS/BIKODC tunnel — no shared Terraform resources besides the DRG, no risk to production if this tunnel misbehaves
- Match the same IKEv2 static-routing security posture already proven by the RRAS tunnel (AES-256/SHA-256/DH-Group14)

**Non-goals**
- Not a replacement for RRAS's tunnel — that continues serving `192.168.1.0/24` unchanged
- Not a redesign of the on-prem LAN/firewall topology — MX68 and BikoFW-SRX's existing roles are unchanged

---

## 2. Architecture Diagram

```
  INTERNET
     │
     │  81.130.238.41 (shared public IP)
     ▼
┌─────────────────────────────┐
│   BT Hub Manager (ISP)       │  192.168.1.254
│   NAT / port-forwarding      │  UDP 500+4500 → BIKODC only
└──────────────┬───────────────┘
               │
               ▼
   ┌───────────────────────────┐        ┌─────────────────────────────┐
   │   192.168.1.0/24           │        │  Tunnel A — tekeche-ipsec    │
   │   • BIKODC   .100           │───────▶│  IKE + ESP UP  ✅            │
   │   • MX68 WAN1 .214          │        │  (see main HLD/LLD)          │
   └──────────────┬──────────────┘        └─────────────────────────────┘
                  │
                  ▼
         ┌─────────────────┐
         │  BikoFW-SRX      │  192.168.128.2 (Juniper SRX300)
         │  routes/firewalls│
         │  between the two │
         │  segments        │
         └────────┬─────────┘
                  │
                  ▼
   ┌───────────────────────────┐        ┌─────────────────────────────┐
   │   192.168.128.0/24         │        │  Tunnel B — tekeche-mx68-    │
   │   • MX68 LAN  .1            │───────▶│  ipsec                       │
   │     (Single LAN mode)       │        │  IKE UP / ESP DOWN  🔴       │
   └──────────────────────────────┘        │  BLOCKED — see §5            │
                                            └───────────────┬─────────────┘
                                                             │
                                            ┌────────────────▼────────────────┐
                                            │      OCI DRG — tekeche-drg       │
                                            │  (shared attachment point for    │
                                            │   both Tunnel A and Tunnel B)    │
                                            └────────────────┬────────────────┘
                                                             │
                                            ┌────────────────▼────────────────┐
                                            │   OCI VCN — 10.0.0.0/16          │
                                            │   uk-london-1, tekeche-pub       │
                                            └───────────────────────────────────┘
```

Full topology diagram (all components, both realms): `Desktop\Tekeche infrastructure\tekeche-network-topology.pdf`, also live at the Claude Artifact URL recorded in project memory.

---

## 3. Key Components

| Component | Role |
|---|---|
| Meraki MX68CW (`Q2NY-MC4Z-JGQR`) | Site appliance for `192.168.128.0/24`; non-Meraki VPN peer client, policy-based |
| BikoFW-SRX (Juniper SRX300) | Firewall/router between `192.168.1.0/24` and `192.168.128.0/24`; not itself a VPN endpoint for this tunnel |
| BT Hub Manager | ISP-side NAT/port-forward device; shared egress for both this tunnel and RRAS's |
| OCI DRG (`tekeche-drg`) | Shared attachment point — same DRG the RRAS tunnel already uses |
| OCI IPSec Connection (`tekeche-mx68-ipsec`) | Two tunnels, static routing, advertises `192.168.128.0/24` into OCI |

---

## 4. Current Status (as of 2026-07-07)

| Tunnel | IKE (Phase 1) | ESP (Phase 2) | Overall |
|---|---|---|---|
| `tekeche-ipsec` (RRAS, reference) | ✅ Established | ✅ Established | ✅ UP |
| `tekeche-mx68-ipsec` — tunnel 1 (`152.67.132.126`) | ✅ Established | ❌ Not established | 🔴 DOWN |
| `tekeche-mx68-ipsec` — tunnel 2 (`152.67.138.186`) | ✅ Established | ❌ Not established | 🔴 DOWN |

IKE reliably completes; ESP (the actual data-plane SA) never comes up. Three independent, verified-correct fixes have not resolved it (see LLD §5 and Implementation Plan). A support case is open with Meraki TAC.

---

## 5. Risks & Constraints

- **Shared public IP with production RRAS tunnel** — any change to the shared egress path (BT Hub Manager, BikoFW-SRX) is classified **HIGH RISK** per change-management rules and requires a maintenance window + explicit approval, since it risks the already-working RRAS tunnel.
- **Policy-based VPN on the Meraki side** (`isRouteBased: false`) — MX68 always proposes narrow Phase 2 traffic selectors; this constrains how the OCI tunnel must be configured (see LLD §2.3).
- **No visibility into Meraki's local VPN daemon log** — the Dashboard API doesn't expose IKE/ESP negotiation failure reasons beyond coarse registry-change events; this is the current bottleneck and is why a TAC case was necessary.

---

## 6. Dependencies

- Meraki TAC response on support case (see Implementation Plan §4 for the exact ask and case content location)
- No OCI or on-prem infrastructure changes are currently planned pending that response
