# Tekeche — High-Level Design (HLD)
## Hybrid On-Premise + Oracle Cloud Infrastructure

**Version:** 1.0  
**Date:** 2026-07-03  
**Author:** Tekeche Engineering

---

## 1. Overview

Tekeche is a ride-hailing and delivery platform serving Côte d'Ivoire. This document describes the hybrid infrastructure architecture that combines an on-premise data centre (primary) with Oracle Cloud Infrastructure (failover/standby), providing high availability, geographic resilience, and a clear path to cloud scale-out.

**Goals**
- 99.9%+ availability for the booking and dispatch API
- Sub-30s automated failover from on-prem to OCI
- Zero-trust secret management (OCI Vault)
- OTA mobile update delivery with no app-store release required
- Cost-optimised: on-prem carries full production load; OCI standby is idle until needed

---

## 2. Architecture Diagram

```
                        ┌─────────────────────────────────────────────┐
                        │           ORACLE CLOUD (ap-* region)         │
                        │                                               │
  INTERNET              │  ┌──────────────────────────────────────────┐│
     │                  │  │        OCI Flexible Load Balancer         ││
     │  HTTPS/443       │  │  • IP_HASH (socket.io sticky sessions)    ││
     └──────────────────┼──│  • Health check: GET /health every 10s    ││
                        │  │  • TLS termination (OCI Certificates)     ││
                        │  └────────────┬─────────────────┬────────────┘│
                        │               │                 │              │
                        │        [PRIMARY]          [DRAINED/STANDBY]   │
                        │               │                 │              │
                        │  ─ ─ ─ ─ ─ ─ ┘                 │              │
                        │  VPN Tunnel (IPSec IKEv2)        │              │
                        │               │            ┌─────┴───────────┐ │
                        │               │            │  OCI Standby VM  │ │
                        │               │            │  Ubuntu 22.04    │ │
                        │               │            │  Node 20 + PM2   │ │
                        │               │            │  Nginx (TLS)     │ │
                        │               │            │  MongoDB RS mbr  │ │
                        │               │            │  Redis replica   │ │
                        │               │            │  10.0.2.10       │ │
                        │               │            └─────────────────-┘ │
                        │               │                  │               │
                        │               │            ┌─────┴──────────┐   │
                        │               │            │   OCI Bastion  │   │
                        │               │            │  (SSH jump)    │   │
                        │               │            └────────────────┘   │
                        │               │                                  │
                        │               │            ┌───────────────────┐ │
                        │               │            │    OCI KMS Vault  │ │
                        │               │            │  AES-256 key      │ │
                        │               │            │  tekeche-api .env │ │
                        │               │            └───────────────────┘ │
                        │               │                                  │
                        │               │     OCI DNS Traffic Management   │
                        │               │     api.tekeche.com → LB IP      │
                        │               │     Failover TTL: 30s            │
                        └───────────────┼──────────────────────────────────┘
                                        │
                    ┌───────────────────┴──────────────────────┐
                    │          ON-PREMISE DATA CENTRE           │
                    │                                           │
                    │  ┌──────────────────────────────────────┐ │
                    │  │   NLB VIP  192.168.1.100             │ │
                    │  │   Windows NLB (ARR cross-server)     │ │
                    │  └────────┬──────────────┬──────────────┘ │
                    │           │              │                 │
                    │    ┌──────┴───┐    ┌─────┴────┐          │
                    │    │ Server 1 │    │ Server 2 │          │
                    │    │ Node/PM2 │    │ Node/PM2 │          │
                    │    │ IIS/ARR  │    │ IIS/ARR  │          │
                    │    └──────────┘    └──────────┘          │
                    │                                           │
                    │  ┌────────────────────────────────────┐  │
                    │  │  MongoDB 8.3  rs0 (PRIMARY)        │  │
                    │  │  Redis (PRIMARY)                   │  │
                    │  │  127.0.0.1 only + VPN peer         │  │
                    │  └────────────────────────────────────┘  │
                    │                                           │
                    │  ┌────────────────────────────────────┐  │
                    │  │  Windows RRAS — IPSec VPN          │  │
                    │  │  Tunnel 1 → OCI DRG (primary)      │  │
                    │  │  Tunnel 2 → OCI DRG (redundant)    │  │
                    │  └────────────────────────────────────┘  │
                    │                                           │
                    │  ┌────────────────────────────────────┐  │
                    │  │  GitHub Actions Self-Hosted Runner  │  │
                    │  │  OTA pipeline (expo export + deploy)│  │
                    │  └────────────────────────────────────┘  │
                    └───────────────────────────────────────────┘
```

---

## 3. Component Inventory

### 3.1 On-Premise (Primary)

| Component | Technology | Role |
|---|---|---|
| Load Balancer VIP | Windows NLB + IIS ARR | Distributes traffic across on-prem nodes; 192.168.1.100 |
| API Servers (×2) | Node.js 20 + PM2 cluster | tekeche-api; zero-downtime reload via `pm2 reload` |
| Web Server | IIS 10 + ARR | Reverse proxy, TLS termination, websocket upgrade |
| Database | MongoDB 8.3 (rs0 PRIMARY) | Ride/booking data; local only (127.0.0.1 + VPN) |
| Cache | Redis (PRIMARY) | Session tokens, socket.io adapter, OTP codes |
| VPN | Windows RRAS IKEv2 | Two IPSec tunnels to OCI DRG |
| OTA Runner | GitHub Actions self-hosted | Builds & deploys expo-updates bundles on git push |
| Security Dashboard | Node.js + JWT | Internal ops panel at security.tekeche.com |

### 3.2 Oracle Cloud Infrastructure (Standby / Failover)

| Component | OCI Service | Role |
|---|---|---|
| Load Balancer | OCI Flexible LB (10–100 Mbps) | Single public ingress; TLS termination; IP_HASH policy |
| Hot Standby VM | Compute VM.Standard.E4.Flex | Mirrors production stack; drained until failover |
| VPN Gateway | DRG + IPSec Connection | Terminates 2 IKEv2 tunnels from on-prem RRAS |
| DNS | OCI DNS Traffic Management | Failover steering policy; 30s TTL; health-checks LB |
| Secret Store | OCI Vault (KMS AES-256) | Stores tekeche-api `.env`; VM reads via IAM dynamic group |
| SSH Access | OCI Bastion (STANDARD) | Managed jump host into private subnet; no public IP on VM |
| Backups | Boot Volume backup (Bronze) | Daily snapshot of standby VM boot disk |

### 3.3 Networking

| Layer | CIDR / Address | Notes |
|---|---|---|
| OCI VCN | 10.0.0.0/16 | All OCI resources |
| Public Subnet (LB) | 10.0.1.0/24 | Internet-facing; IGW route |
| Private Subnet (VM) | 10.0.2.0/24 | No public IP; NAT for egress; DRG for on-prem |
| On-prem LAN | 192.168.1.0/24 | Routed via VPN |
| On-prem NLB VIP | 192.168.1.100 | Primary backend for OCI LB |
| OCI Standby IP | 10.0.2.10 | Drained backend; activated on failover |

---

## 4. Traffic Flow

### 4.1 Normal (On-Prem Primary)

```
Mobile App
  → HTTPS api.tekeche.com
  → OCI DNS (A record → LB public IP)
  → OCI Flexible LB  [health check: on-prem /health = 200 ✓]
  → VPN tunnel (IPSec IKEv2)
  → On-prem NLB VIP 192.168.1.100
  → IIS ARR
  → Node.js PM2 cluster (port 5000)
  → MongoDB rs0 PRIMARY + Redis
```

### 4.2 Failover (On-Prem Unreachable)

```
OCI LB health check: on-prem /health fails ×2 (20s)
  → LB marks on-prem backend CRITICAL
  → OCI LB routes to OCI Standby (10.0.2.10)  [un-drained automatically if only backend]
  → OCI VM: Nginx → PM2 → Node.js
  → MongoDB rs0 SECONDARY (10.0.2.10) promoted to PRIMARY
  → Redis: REPLICAOF NO ONE (manual or scripted)
OCI DNS health monitor: LB IP still answers → no DNS change required
```

### 4.3 OTA Update Delivery

```
git push → GitHub Actions (self-hosted runner, on-prem)
  → expo export --platform all
  → ota-deploy.js copies dist bundles to api server
  → Expo client fetches manifest from api.tekeche.com/updates/manifest/:variant
  → Bundle downloaded on first cold start, applied on second
```

---

## 5. Data Replication

### MongoDB Replica Set (rs0)

| Member | Role | Priority | Notes |
|---|---|---|---|
| On-prem (127.0.0.1) | PRIMARY | 1 | Accepts all writes |
| OCI Standby (10.0.2.10) | SECONDARY | 0 | Read-only; votes=0; replicates over VPN |

- Replication lag target: < 5s under normal load
- On failover: `rs.stepDown()` on primary (if reachable), then `rs.reconfig()` to promote OCI member

### Redis

| Instance | Role | Notes |
|---|---|---|
| On-prem | PRIMARY | Accepts all writes |
| OCI Standby | REPLICA (read-only) | `replicaof 192.168.1.100 6379` via VPN |

- On failover: `REPLICAOF NO ONE` on OCI instance to promote to primary

---

## 6. Security

| Concern | Control |
|---|---|
| Secret management | OCI Vault (AES-256 HSM key); VM reads via IAM dynamic group; no secrets in git |
| Network isolation | OCI standby in private subnet; no public IP; Bastion for SSH access |
| TLS | OCI LB terminates TLS (OCI Certificates); on-prem uses self-signed internally |
| VPN | IKEv2, AES-256-GCM, SHA2-256, PFS GROUP14; 2 redundant tunnels |
| API auth | JWT (RS256); OTP via Brevo SMS/email; rate-limited per IP |
| MongoDB | Auth enabled; bindIp restricted to 127.0.0.1 + VPN peer only |
| Redis | Bind to 127.0.0.1 + VPN peer; no public exposure |
| SSH | On-prem: direct; OCI: Bastion-only (managed session, max 3h TTL) |

---

## 7. Failover Runbook (Summary)

1. **Detection** — OCI LB health check fails ×2 in 20s OR ops team is paged
2. **Verify** — `curl https://api.tekeche.com/health` and `pm2 status` on on-prem nodes
3. **Activate OCI standby**:
   - Un-drain OCI standby in LB console (if not automatic)
   - `REPLICAOF NO ONE` on OCI Redis
   - Promote MongoDB: `rs.reconfig(...)` with OCI member priority:1
4. **Validate** — `curl https://api.tekeche.com/health` returns `{"status":"ok"}`
5. **Restore on-prem** (when ready):
   - Restart services; re-add as RS member
   - `REPLICAOF 192.168.1.100 6379` on OCI Redis
   - Re-drain OCI standby in LB console
   - Confirm on-prem is PRIMARY again

**RTO target:** < 5 minutes  
**RPO target:** < 30 seconds (MongoDB RS replication lag)

---

## 8. Terraform File Map

```
ops/oci/
├── main.tf                  OCI provider, Terraform version
├── variables.tf             All input variables
├── terraform.tfvars.example Starter values (commit-safe)
├── networking.tf            VCN, IGW, NAT, DRG, subnets, security lists, Bastion
├── vpn.tf                   CPE, IPSec connection, 2 IKEv2 tunnel configs
├── compute.tf               Hot-standby VM, boot volume backup
├── cloud_init.tpl           VM bootstrap (Node, MongoDB, Redis, PM2, Nginx)
├── loadbalancer.tf          Flexible LB, backend sets, listeners, rule sets
├── dns.tf                   DNS zone, health monitor, Traffic Management policy
├── vault.tf                 KMS vault, AES-256 key, IAM dynamic group + policy
└── outputs.tf               LB IP, VPN IPs, standby IP, Bastion, post-apply checklist
```

---

## 9. Key Design Decisions

| Decision | Rationale |
|---|---|
| On-prem as primary, OCI as standby | Minimises OCI running costs; on-prem hardware already paid for |
| OCI LB in front of on-prem | Single public IP regardless of failover state; no DNS change needed during failover |
| IP_HASH LB policy | socket.io requires sticky sessions; IP_HASH is stateless (no shared session table needed) |
| IPSec IKEv2 with 2 tunnels | OCI provides 2 tunnel IPs per connection; RRAS uses both for path redundancy |
| MongoDB RS with priority:0 OCI member | OCI standby never becomes PRIMARY automatically; prevents split-brain during VPN flap |
| OCI Vault for secrets | Avoids `.env` in git or baked into AMI; VM fetches at boot via instance principal |
| OTA updates via self-hosted runner | Keeps bundle delivery on-prem; avoids GitHub-hosted runner egress costs |
