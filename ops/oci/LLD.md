# Tekeche — Low-Level Design (LLD)
## Hybrid On-Premise + Oracle Cloud Infrastructure

**Version:** 1.0  
**Date:** 2026-07-03  
**Reference HLD:** `ops/oci/HLD.md`

---

## 1. API Server — Express Application

### 1.1 Process Model

| Item | Value |
|---|---|
| Runtime | Node.js 20.x |
| Process manager | PM2 cluster mode (`ecosystem.config.js`) |
| Port | 5000 (internal only) |
| Trust proxy | `1` (IIS/ARR strips X-Forwarded-For) |
| Body limit | 10 KB (`express.json`) |
| Log format | `combined` (production), `dev` (other) |

### 1.2 Middleware Stack (execution order)

```
Request
  │
  ├─ helmet()            — CSP, HSTS (maxAge=31536000), frameguard=deny, referrer=strict-origin
  ├─ cors()              — allowedOrigins from CORS_ORIGINS env var; maxAge=86400
  ├─ express.json()      — limit 10kb; rawBody captured for webhook verification
  ├─ mongoSanitize()     — strips MongoDB operator injection ($, .)
  ├─ securityMonitor     — logs suspicious patterns (custom middleware)
  ├─ watchlist           — blocks known bad IPs/user agents
  ├─ appToken            — validates X-App-Token header for mobile clients
  ├─ morgan()            — access log
  ├─ rateLimit (global)  — /api/*: 100 req/15min/IP; skip 127.0.0.1/::1
  ├─ otpLimiter          — /api/auth/send-otp: 10 req/min/IP
  ├─ otpIdentifierLimiter— /api/auth/send-otp: 15 req/10min/identifier (DB-backed, cross-worker)
  ├─ rideLimiter         — /api/rides/request: 5 req/min/IP
  ├─ walletTopupLimiter  — /api/wallet/topup: 5 req/min/IP
  │
  └─ Routes (see §1.3)
        └─ errorHandler  — catches ApiError, sends JSON {success:false, message, code}
```

**IP key generation:** `(req.ip || '').replace(/:\d+$/, '')` — strips port suffix added by IIS ARR.

### 1.3 Route Map

| Mount | Module | Notes |
|---|---|---|
| `GET /` | inline | Returns name/version/env/status JSON |
| `GET /health` | inline | Returns `{status, db, version, env, timestamp}`; 200=ok, 503=degraded |
| `/api/auth` | auth.routes | OTP send/verify, refresh, logout, delete-account |
| `/api/rides` | rides.routes | Request, accept, cancel, complete, rate |
| `/api/wallet` | wallet.routes | Balance, topup, history |
| `/api/emergency` | emergency.routes | SOS contacts CRUD |
| `/api/promo` | promo.routes | Promo code validation |
| `/api/drivers` | driver.routes | Profile, KYC upload, availability toggle |
| `/api/admin` | admin.routes | Behind `adminIpGuard` middleware |
| `/api/woyo` | woyo.routes | Woyo booking, localites list |
| `/api/notify` | notify.routes | Push token registration |
| `/api/payment` | payment.routes | Orange Money, MTN MoMo, Wave, Paystack initiation |
| `/api/chat` | chat.routes | Message history for trips |
| `/api/food` | food.routes | Food order placement/tracking |
| `/api/supplier` | supplier.routes | Supplier CRUD |
| `/api/support` | support.routes | Support ticket creation |
| `/portal` | portal.routes | Supplier web portal (JWT-based, inline CSP override) |
| `/woyo` | woyo.admin.controller | Woyo admin dashboard (inline CSP override) |
| `/menu` | menuAdmin.routes | Menu admin dashboard (inline auth key) |
| `/updates` | updates.routes | OTA manifest + bundle serving |
| `/security` | security.routes | Security dashboard |
| `GET /track/:tripId` | inline | Public trip tracking page (HTML, auto-refresh 15s) |
| `GET /payment/return` | payment.controller | Payment return page |
| `GET /uploads/kyc/*` | static | JWT-protected KYC document serving |

### 1.4 Health Check Response

```json
{
  "status": "ok",
  "db": "connected",
  "version": "1.0.0",
  "env": "production",
  "timestamp": "2026-07-03T10:00:00.000Z"
}
```

- HTTP 200 when `mongoose.connection.readyState === 1`
- HTTP 503 when disconnected (`"status": "degraded"`)
- OCI LB health checker matches regex `.*"status":"ok".*`

---

## 2. Authentication

### 2.1 OTP Flow

```
Client                        API                           Brevo
  │                             │                              │
  ├─ POST /api/auth/send-otp ──►│                              │
  │   {email, phone, name}      │                              │
  │                             ├─ generate 6-digit code       │
  │                             │   crypto.randomInt(100000,   │
  │                             │   1000000)                   │
  │                             ├─ OTP.create({identifier,     │
  │                             │   code, expiresAt+5min})     │
  │                             ├─ sendOTP(email, code, name,  │
  │                             │   phone)                     │
  │                             │   ├─ SMTP: smtp-relay.       │──► email OTP
  │                             │   │  brevo.com:587 STARTTLS  │
  │                             │   └─ SMS: api.brevo.com/v3/  │──► SMS OTP
  │                             │      transactionalSMS/sms    │
  │◄── {success:true, method}───│                              │
  │                             │                              │
  ├─ POST /api/auth/verify-otp ►│                              │
  │   {email/phone, code}       ├─ OTP.findOne({identifier,    │
  │                             │   code, used:false,          │
  │                             │   expiresAt:{$gt:now}})      │
  │                             ├─ OTP.markUsed()              │
  │                             ├─ User/Driver.findOrCreate()  │
  │                             ├─ JWT sign (RS256 or HS256,   │
  │                             │   exp:7d, jti:uuid)          │
  │                             ├─ RefreshToken.create(        │
  │                             │   exp:30d)                   │
  │◄── {token, refreshToken,    │                              │
  │     user/driver}            │                              │
```

### 2.2 JWT Structure

| Field | Value |
|---|---|
| Algorithm | HS256 (JWT_SECRET env var, min 32 chars) |
| Access token TTL | 7 days |
| Refresh token TTL | 30 days |
| `jti` | UUID (for revocation via RevokedToken collection) |
| `role` | `passenger` \| `driver` \| `admin` |
| Revocation check | Socket.io middleware + any route using `auth` middleware |

### 2.3 Phone Normalisation

```
Input → Normalised (E.164 for CI)
"0102345678"     → "+22502345678" (CI 0X prefix)
"225-01 23 45"   → "+2250123456789"
"00225012345678" → "+225012345678"
"+22501234567"   → "+22501234567" (pass-through)
```

### 2.4 OTP Rate Limits

| Limit | Window | Max | Scope | Backend |
|---|---|---|---|---|
| Global OTP | 1 min | 10 | Per IP | express-rate-limit (memory) |
| Identifier OTP | 10 min | 15 | Per email/phone | MongoDB `OtpRateLimit` collection (cross-worker) |
| Ride request | 1 min | 5 | Per IP | express-rate-limit (memory) |
| Wallet topup | 1 min | 5 | Per IP | express-rate-limit (memory) |
| Global API | 15 min | 100 | Per IP | express-rate-limit (memory) |

---

## 3. Socket.io

### 3.1 Server Configuration

```javascript
new Server(server, {
  cors: { origin: CORS_ORIGINS },
  transports: ['websocket', 'polling'],
})
```

### 3.2 Redis Adapter (cross-node fan-out)

| Item | Value |
|---|---|
| Package | `@socket.io/redis-adapter` |
| Config | `REDIS_URL` env var |
| Reconnect strategy | `Math.min(retries * 200, 5000)` ms |
| Fallback | In-memory adapter (single-node) when Redis unavailable |
| Pub client | `createClient({ url: REDIS_URL })` |
| Sub client | `pub.duplicate()` |

Without the Redis adapter, `io.to(room).emit()` only reaches sockets on the **same PM2 worker process**. This caused the dispatch outage where drivers on worker B never received `new_ride_request` emitted by worker A.

### 3.3 Socket Rooms

| Room | Who joins | Purpose |
|---|---|---|
| `user_<userId>` | Every authenticated socket | Direct messages to a specific user |
| `admin_room` | Admin role sockets | Admin broadcast events |

### 3.4 Socket Events (Server → Client)

| Event | Payload | Recipient |
|---|---|---|
| `new_ride_request` | tripId, passenger, pickup, dropoff, estimatedFare, distanceKm, surgeMultiplier, vehicleType, timeout | Driver socket |
| `driver_location_update` | `{lat, lng}` | Passenger of active trip |
| `no_driver_found` | `{tripId}` | Passenger |
| `receive_message` | Message document | Both chat participants |
| `receive_order_message` | Message document | Both food order chat participants |

### 3.5 Socket Events (Client → Server)

| Event | Payload | Handler |
|---|---|---|
| `driver_location` | `{lat, lng}` | Throttled 1/5s; updates Driver.location; emits to passenger |
| `send_message` | `{tripId, text}` | Creates Message; emits to both parties; max 500 chars |
| `mark_seen` | `{tripId}` | Updates Message.seen for other party's messages |
| `send_order_message` | `{orderId, text}` | Food order chat |
| `mark_order_seen` | `{orderId}` | Food order chat seen state |

### 3.6 Driver Connectivity Lifecycle

```
connect  → Driver.findByIdAndUpdate(socketId, isOnline=true, isAvailable=true)
         → Check for pending Trip (status=searching, vehicleType match, createdAt >-15min)
         → If found → dispatchRide(pendingTrip)

disconnect → Only mark offline if Driver.socketId === this socket.id
           → (prevents stale reconnect sockets from clobbering the live one)
```

---

## 4. Dispatch Engine

### 4.1 Algorithm

```
dispatchRide(trip, excludeIds=[])
  │
  ├─ findNearbyDrivers(lat, lng, vehicleType, 1000km, excludeIds)
  │   └─ Driver.find({
  │        isOnline:true, isAvailable:true,
  │        kycStatus:{$in:['verified','approved']},
  │        vehicleType: <trip.vehicleType>,
  │        location: { $near: { $geometry: Point[lng,lat], $maxDistance: 1000000 } }
  │      }).limit(10)
  │
  ├─ If no drivers → broadcastToOfflineDrivers(trip) → return false
  │
  ├─ Priority: socket > push > email
  │   selected = socketDrivers[0] || pushDrivers[0] || emailDrivers[0]
  │
  ├─ Driver.isAvailable = false
  │
  ├─ sendTripRequest(io, trip, driver)
  │   ├─ socket: io.to(driver.socketId).emit('new_ride_request', payload)
  │   │         + sendSmsFallback(driver, trip) [parallel]
  │   ├─ push:  sendPushNotification(driver.pushToken, ...)
  │   └─ email: sendEmailFallback(driver, trip) [if no socket AND no push]
  │
  └─ setTimeout(timeoutMs)
      ├─ If trip.status !== 'searching' → noop (already accepted/cancelled)
      ├─ Driver.isAvailable = true
      └─ dispatchRide(trip, [...excludeIds, driver._id])  [recursive]
          └─ If no driver after all retries:
              └─ Trip.status = 'cancelled', cancelledBy='system'
              └─ escrow.refund(passenger, tripId, reservedFare)
              └─ io.to(`user_${passenger}`).emit('no_driver_found')
```

### 4.2 Timeouts

| Channel | Timeout |
|---|---|
| Socket + push | `DISPATCH_TIMEOUT_SECONDS` env var (default 120s) |
| Email-only driver | 5 minutes (300s) |

### 4.3 Fallback Notifications

| Priority | Condition | Channel |
|---|---|---|
| 1 | `driver.socketId` set | WebSocket `new_ride_request` + SMS (parallel) |
| 2 | `driver.pushToken` set, no socket | Expo push notification |
| 3 | Neither | Email (HTML, links to Play Store internal test) |
| Broadcast | Zero eligible online drivers | Email all active KYC-approved drivers |

---

## 5. Data Models

### 5.1 User

```javascript
{
  phone:        String (unique, sparse, E.164)
  email:        String (unique, sparse, lowercase)
  name:         String
  surname:      String
  avatar:       String (URL)
  rating:       Number (1–5, default 5.0)
  totalTrips:   Number
  referralCode: String (unique, auto-generated: "TEKECHE" + 5 random alphanums)
  referredBy:   ObjectId → User
  isActive:     Boolean
  pushToken:    String (Expo push token)
  createdAt, updatedAt
}
```

### 5.2 Driver

```javascript
{
  phone:               String (unique, sparse)
  email:               String (unique, sparse, lowercase)
  name:                String (required)
  avatar:              String
  vehicleType:         enum ['standard','moto','comfort','xl','delivery']
  vehiclePlate:        String (uppercase)
  vehicleModel:        String
  driversLicenseExpiry: Date
  kycStatus:           enum ['pending','verified','approved','rejected']
  isOnline:            Boolean
  isAvailable:         Boolean
  location:            GeoJSON Point { type:'Point', coordinates:[lng,lat] }
  rating:              Number (1–5, default 5.0)
  totalTrips:          Number
  totalEarnings:       Number (FCFA)
  socketId:            String (current socket.io connection ID)
  lastSeen:            Date
  pushToken:           String
  isActive:            Boolean
  woyo:                Boolean (enrolled in Woyo service)
  woyoLocalite:        ObjectId → Localite
  woyoTermsAccepted:   Boolean
  kycDocuments: [{
    type: enum ['national_id_front','national_id_back','drivers_license',
                'vehicle_photo','selfie','vehicle_insurance',
                'vehicle_roadworthiness','criminal_record']
    url: String
    uploadedAt: Date
  }]
  createdAt, updatedAt
}
Index: { location: '2dsphere' }
```

### 5.3 Trip

```javascript
{
  passenger:        ObjectId → User (required)
  driver:           ObjectId → Driver
  vehicleType:      enum ['standard','moto','comfort','xl','delivery']
  pickup:           { address:String, coordinates:{lat,lng} }
  dropoff:          { address:String, coordinates:{lat,lng} }
  estimatedDistance: Number (km)
  estimatedDuration: Number (minutes)
  estimatedFare:    Number (FCFA, required)
  finalFare:        Number
  reservedFare:     Number (wallet escrow amount)
  surgeMultiplier:  Number (default 1.0)
  paymentMethod:    enum ['orange_money','mtn_momo','wave','wallet','cash']
  paymentStatus:    enum ['pending','awaiting_payment','paid','failed']
  mobilePaymentRef: String
  mobilePaymentUrl: String
  promoCode:        String
  promoDiscount:    Number
  scheduledFor:     Date
  isPool:           Boolean
  poolGroupId:      ObjectId → Trip
  serviceType:      enum ['standard','woyo']
  woyoCapacity:     Number (default 4)
  woyoPassengers: [{
    passenger: ObjectId → User
    pickup:    { address, coordinates }
    dropoff:   { address, coordinates }
    fare:      Number (default 200 FCFA)
    status:    enum ['waiting','boarding','onboard','dropped']
    boardedAt, droppedAt: Date
  }]
  status: enum ['scheduled','searching','accepted','driver_arriving',
                'in_progress','completed','cancelled']
  cancelledBy:  enum ['passenger','driver','system']
  cancelReason: String
  driverRating, passengerRating: Number (1–5)
  driverRatingComment, passengerRatingComment: String
  startedAt, completedAt: Date
  createdAt, updatedAt
}
```

### 5.4 Localite (Woyo zones)

```javascript
{
  name:     String (required) — e.g. "Cocody", "Yamoussoukro"
  fare:     Number (FCFA, default 250)
  isActive: Boolean (default true)
  parentId: ObjectId → Localite (null = top-level)
  createdAt, updatedAt
}
Index: { name: 1, parentId: 1 } (unique)
```

Total zones: 69 (communes + cities across Côte d'Ivoire)

### 5.5 OTP

```javascript
{
  identifier: String (email or phone)
  code:       String (6 digits)
  used:       Boolean (default false)
  expiresAt:  Date (+OTP_EXPIRY_MINUTES, default 5 min)
  createdAt
}
TTL index: { expiresAt: 1 }, expireAfterSeconds: 0
```

### 5.6 OtpRateLimit (DB-backed, cross-worker)

```javascript
{
  identifier: String (unique)
  count:      Number
  resetAt:    Date (+10 min window)
}
```

---

## 6. MongoDB

### 6.1 Connection Configuration

```javascript
{
  serverSelectionTimeoutMS: 30000,
  socketTimeoutMS:          45000,
  heartbeatFrequencyMS:     10000,
  retryReads:               true,
  retryWrites:              true,
  maxPoolSize:              10,
}
```

URI: `MONGODB_URI` env var (default `mongodb://localhost:27017/tekeche`)

### 6.2 Replica Set (rs0)

| Member | Host | Priority | Votes | Role |
|---|---|---|---|---|
| Primary | `127.0.0.1:27017` (on-prem) | 1 | 1 | PRIMARY, accepts all writes |
| Secondary | `10.0.2.10:27017` (OCI standby) | 0 | 0 | SECONDARY, replication only |

**mongod.conf (on-prem primary)**
```yaml
net:
  port: 27017
  bindIp: 127.0.0.1,192.168.1.100
security:
  authorization: enabled
replication:
  replSetName: rs0
```

**mongod.conf (OCI standby)**
```yaml
net:
  port: 27017
  bindIp: 127.0.0.1,10.0.2.10
security:
  authorization: enabled
replication:
  replSetName: rs0
```

### 6.3 Add OCI Standby to RS

Run from on-prem `mongosh`:
```javascript
rs.add({ host: "10.0.2.10:27017", priority: 0, votes: 0 })
```

On-prem firewall must allow TCP 27017 from `10.0.2.0/24` (via VPN).

### 6.4 Key Indexes

| Collection | Index | Type |
|---|---|---|
| Driver | `location` | 2dsphere |
| Driver | `{ vehicleType, isOnline, isAvailable, kycStatus }` | Compound |
| OTP | `expiresAt` | TTL (expireAfterSeconds:0) |
| OtpRateLimit | `identifier` | Unique |
| Localite | `{ name, parentId }` | Unique compound |

---

## 7. Redis

### 7.1 Configuration

| Item | On-prem (PRIMARY) | OCI Standby (REPLICA) |
|---|---|---|
| Version | System Redis | Redis (latest stable) |
| Bind | `127.0.0.1 192.168.1.100` | `127.0.0.1 10.0.2.10` |
| Port | 6379 | 6379 |
| Replication | — | `replicaof 192.168.1.100 6379` |
| Read-only | — | `replica-read-only yes` |

### 7.2 Redis Use Cases

| Use Case | Description |
|---|---|
| Socket.io adapter | Pub/sub for cross-worker fan-out (REDIS_URL env var) |
| Session tokens | (future) |
| OTP cache | (planned migration from MongoDB) |

### 7.3 Failover Promotion

```bash
# On OCI Redis, run:
redis-cli -h 127.0.0.1 REPLICAOF NO ONE
# Verify:
redis-cli -h 127.0.0.1 INFO replication | grep role
# Expected: role:master
```

---

## 8. OCI Network — Exact Specifications

### 8.1 VCN Resources

| Resource | Name | Value |
|---|---|---|
| VCN | tekeche-vcn | 10.0.0.0/16 |
| Internet Gateway | tekeche-igw | Attached to VCN |
| NAT Gateway | tekeche-nat | Outbound-only for private subnet |
| DRG | tekeche-drg | VPN termination point |
| Public Subnet | tekeche-public-subnet | 10.0.1.0/24 (LB lives here) |
| Private Subnet | tekeche-private-subnet | 10.0.2.0/24 (VM lives here, no public IP) |

### 8.2 Route Tables

**Public route table (LB subnet)**
| Destination | Next hop |
|---|---|
| 0.0.0.0/0 | Internet Gateway |

**Private route table (VM subnet)**
| Destination | Next hop |
|---|---|
| 0.0.0.0/0 | NAT Gateway |
| 192.168.1.0/24 | DRG (via VPN) |

### 8.3 Security Lists

**Public security list (10.0.1.0/24)**
| Direction | Protocol | Source/Dest | Port | Purpose |
|---|---|---|---|---|
| Ingress | TCP | 0.0.0.0/0 | 443 | HTTPS from internet |
| Ingress | TCP | 0.0.0.0/0 | 80 | HTTP redirect |
| Egress | All | 0.0.0.0/0 | All | All outbound |

**Private security list (10.0.2.0/24)**
| Direction | Protocol | Source/Dest | Port | Purpose |
|---|---|---|---|---|
| Ingress | TCP | 10.0.1.0/24 | 443 | LB → VM (HTTPS) |
| Ingress | TCP | 10.0.1.0/24 | 5000 | LB → VM (API direct) |
| Ingress | TCP | 192.168.1.0/24 | 27017 | MongoDB RS replication from on-prem |
| Ingress | TCP | 192.168.1.0/24 | 6379 | Redis replication from on-prem |
| Ingress | TCP | 10.0.0.0/16 | 22 | SSH within VCN (Bastion) |
| Egress | All | 0.0.0.0/0 | All | All outbound |

---

## 9. VPN — IPSec IKEv2

### 9.1 Phase 1 (IKE SA)

| Parameter | Value |
|---|---|
| Version | IKEv2 |
| Authentication | Pre-shared key (PSK) |
| Auth algorithm | SHA2-256 |
| Encryption | AES-256-CBC |
| DH Group | GROUP14 (2048-bit MODP) |
| Lifetime | 28800 seconds (8 hours) |

### 9.2 Phase 2 (IPSec SA)

| Parameter | Value |
|---|---|
| Auth algorithm | HMAC-SHA2-256-128 |
| Encryption | AES-256-GCM |
| PFS | Enabled (GROUP14) |
| Lifetime | 3600 seconds (1 hour) |
| Routing | STATIC |

### 9.3 Tunnels

| Tunnel | OCI IP | Purpose |
|---|---|---|
| Tunnel 1 | (from `terraform output vpn_tunnel1_ip`) | Primary |
| Tunnel 2 | (from `terraform output vpn_tunnel2_ip`) | Redundant |

### 9.4 Windows RRAS Configuration

```powershell
# Run on on-prem server (after terraform apply)
$tunnel1 = "<vpn_tunnel1_ip>"
$tunnel2 = "<vpn_tunnel2_ip>"
$secret  = "<vpn_shared_secret>"

Add-VpnS2SInterface -Name "OCI-Tunnel1" -Destination $tunnel1 `
  -AuthenticationMethod PSKOnly -SharedSecret $secret `
  -EncryptionType MaximumEncryption -Protocol IKEv2

Add-VpnS2SInterface -Name "OCI-Tunnel2" -Destination $tunnel2 `
  -AuthenticationMethod PSKOnly -SharedSecret $secret `
  -EncryptionType MaximumEncryption -Protocol IKEv2

# Static route: OCI VCN CIDR via primary tunnel
New-NetRoute -DestinationPrefix "10.0.0.0/16" `
  -InterfaceAlias "OCI-Tunnel1" -RouteMetric 1

New-NetRoute -DestinationPrefix "10.0.0.0/16" `
  -InterfaceAlias "OCI-Tunnel2" -RouteMetric 10  # higher metric = backup

# Allow MongoDB replication through firewall
New-NetFirewallRule -DisplayName "OCI-MongoDB-RS" -Direction Inbound `
  -Protocol TCP -LocalPort 27017 `
  -RemoteAddress "10.0.2.0/24" -Action Allow

New-NetFirewallRule -DisplayName "OCI-Redis-Replica" -Direction Inbound `
  -Protocol TCP -LocalPort 6379 `
  -RemoteAddress "10.0.2.0/24" -Action Allow
```

---

## 10. OCI Load Balancer — Exact Configuration

### 10.1 Load Balancer

| Parameter | Value |
|---|---|
| Shape | Flexible |
| Min bandwidth | `lb_min_bandwidth_mbps` (default 10 Mbps) |
| Max bandwidth | `lb_max_bandwidth_mbps` (default 100 Mbps) |
| Subnet | Public subnet (10.0.1.0/24) |
| Public IP | Assigned (see `terraform output lb_public_ip`) |

### 10.2 Backend Sets

**onprem-backends (PRIMARY)**
| Parameter | Value |
|---|---|
| Policy | IP_HASH (sticky by client IP) |
| Health check protocol | HTTPS |
| Health check path | `/health` |
| Health check port | 443 (on-prem NLB VIP) |
| Expected return code | 200 |
| Response regex | `.*"status":"ok".*` |
| Interval | 10,000 ms |
| Timeout | 5,000 ms |
| Retries before critical | 2 |
| Session persistence cookie | `X-TEKECHE-LB` |
| SSL verify peer | false (on-prem uses private cert) |
| Backend | `192.168.1.100:443` weight=1 drain=false |

**oci-standby (DRAINED)**
| Parameter | Value |
|---|---|
| Policy | IP_HASH |
| Health check | Same as above, port 443 on 10.0.2.10 |
| SSL verify peer | false |
| Backend | `10.0.2.10:443` weight=1 **drain=true** |

### 10.3 Listeners

**HTTPS listener (port 443)**
| Parameter | Value |
|---|---|
| Protocol | HTTP (LB terminates TLS) |
| Default backend set | onprem-backends |
| Idle timeout | 300 seconds |
| SSL protocols | TLSv1.2, TLSv1.3 |
| Cipher suite | `oci-default-ssl-cipher-suite-v1` |
| Certificate | OCI Certificates managed cert (`lb_cert_id`) |
| Rule sets | `failover-rules` |

**HTTP listener (port 80)**
| Parameter | Value |
|---|---|
| Protocol | HTTP |
| Rule sets | `http-to-https` (301 redirect) |

### 10.4 Rule Sets

**http-to-https**
```
REDIRECT / → https://<host>:<port>/<path>  (301)
```

**failover-rules**
```
FORWARD /updates/* → onprem-backends  (OTA bundles always served from on-prem)
FORWARD /*         → onprem-backends  (normal traffic; standby activates when primary critical)
```

---

## 11. OCI Compute — Hot Standby VM

### 11.1 Instance Spec

| Parameter | Value |
|---|---|
| Shape | VM.Standard.E4.Flex |
| OCPUs | `standby_ocpus` (default 1) |
| Memory | `standby_memory_gb` (default 8 GB) |
| OS | Ubuntu 22.04 (canonical image) |
| Private IP | 10.0.2.10 (fixed) |
| Public IP | None |
| Boot volume | 50 GB |
| Backup policy | Bronze (daily snapshot) |

### 11.2 cloud-init Bootstrap Sequence

```
1. apt-get: curl gnupg nginx git openssl
2. Node.js 20 (nodesource setup_20.x)
3. npm install -g pm2
4. MongoDB 8 (mongodb-org repo, jammy)
   - /etc/mongod.conf: bindIp=127.0.0.1,10.0.2.10, rs0, auth enabled
   - systemctl enable mongod
5. Redis (apt)
   - replicaof 192.168.1.100 6379
   - replica-read-only yes
   - systemctl enable redis-server
6. git clone <github_repo_url> /opt/tekeche-api
7. npm ci --omit=dev
8. Fetch .env from OCI Vault (if app_env_secret_id set):
     oci secrets secret-bundle get --secret-id <id> | base64 -d > .env
9. pm2 start ecosystem.config.js --env production
10. pm2 save && pm2 startup systemd -u root
11. openssl self-signed cert (CN=api.tekeche.com)
12. Nginx config:
    - upstream: 127.0.0.1:5000, keepalive 32
    - Port 80: redirect → 443
    - Port 443: TLS, proxy_pass http://api
    - /socket.io/: Upgrade header, proxy_read_timeout 86400
    - /: proxy_connect_timeout 10s, proxy_read_timeout 60s
13. systemctl enable nginx
```

### 11.3 Nginx Config (OCI Standby)

```nginx
upstream api {
  server 127.0.0.1:5000;
  keepalive 32;
}
server {
  listen 80;
  return 301 https://$host$request_uri;
}
server {
  listen 443 ssl http2;
  server_name api.tekeche.com;
  ssl_certificate     /etc/ssl/certs/tekeche-selfsigned.crt;
  ssl_certificate_key /etc/ssl/private/tekeche-selfsigned.key;
  ssl_protocols       TLSv1.2 TLSv1.3;
  ssl_ciphers         HIGH:!aNULL:!MD5;

  location /socket.io/ {
    proxy_pass         http://api;
    proxy_http_version 1.1;
    proxy_set_header   Upgrade    $http_upgrade;
    proxy_set_header   Connection "upgrade";
    proxy_set_header   Host       $host;
    proxy_read_timeout 86400;
  }
  location / {
    proxy_pass            http://api;
    proxy_http_version    1.1;
    proxy_set_header      Host              $host;
    proxy_set_header      X-Real-IP         $remote_addr;
    proxy_set_header      X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header      X-Forwarded-Proto $scheme;
    proxy_connect_timeout 10s;
    proxy_read_timeout    60s;
  }
}
```

---

## 12. OCI DNS Traffic Management

### 12.1 Health Monitor

| Parameter | Value |
|---|---|
| Protocol | HTTPS |
| Target | OCI LB public IP |
| Port | 443 |
| Path | `/health` |
| Interval | 30 seconds |
| Expected | HTTP 200 |

### 12.2 Steering Policy

| Parameter | Value |
|---|---|
| Template | FAILOVER |
| TTL | 30 seconds |
| Answer | `lb-primary` A record → LB public IP |
| Rules | FILTER (healthy only) → PRIORITY (lb-primary=1) → LIMIT (1) → RETURN |

### 12.3 DNS Record

```
api.tekeche.com  A  <lb_public_ip>  TTL=30  (via steering policy attachment)
```

---

## 13. OCI Vault

### 13.1 Vault

| Parameter | Value |
|---|---|
| Type | DEFAULT |
| Key | AES-256, HSM protection |
| Secret name | `tekeche-api-env` |
| Secret content | base64-encoded `.env` file |

### 13.2 IAM Policy

```
Allow dynamic-group tekeche-standby-dg to read secret-bundles in compartment id <compartment_ocid>
Allow dynamic-group tekeche-standby-dg to use keys in compartment id <compartment_ocid>
```

Dynamic group matching rule:
```
ANY { instance.id = '<standby_instance_ocid>' }
```

### 13.3 Secret Upload (one-time / on rotation)

```bash
base64 -w 0 /path/to/.env > /tmp/env_b64.txt
oci vault secret create-base64 \
  --compartment-id <compartment_ocid> \
  --secret-name tekeche-api-env \
  --vault-id $(terraform output vault_ocid) \
  --key-id $(terraform output master_key_ocid) \
  --secret-content-content $(cat /tmp/env_b64.txt)
```

Secret rotation:
```bash
oci vault secret update-base64 \
  --secret-id <secret_ocid> \
  --secret-content-content $(base64 -w 0 /path/to/new.env)
```

---

## 14. OTA (Over-the-Air) Update Delivery

### 14.1 Pipeline (GitHub Actions, self-hosted runner)

```yaml
# .github/workflows/ota.yml
trigger: push to main (paths: app/**)
steps:
  1. Checkout
  2. Setup Node.js 20
  3. npm ci
  4. npx expo export --platform all (outputs dist-passenger/, dist-driver/)
  5. node ota-deploy.js
     # copies bundles to /updates/<variant>/ served by /updates route
```

### 14.2 OTA Update Client Flow

```
App cold start #1
  ├─ fetch GET api.tekeche.com/updates/manifest/<variant>
  ├─ manifest returns {updateId, assets[]}
  ├─ download new bundle in background
  └─ app continues on OLD bundle

App cold start #2
  └─ applies downloaded bundle → running new code
```

### 14.3 Manifest Endpoint Behaviour

| Header | Value |
|---|---|
| Cache-Control | `no-store` |
| ETag | Not sent |
| Content-Type | `application/json` |

---

## 15. Environment Variables Reference

| Variable | Required | Description |
|---|---|---|
| `NODE_ENV` | Yes | `production` \| `development` |
| `PORT` | No | API port (default 5000) |
| `MONGODB_URI` | Yes | Full MongoDB connection string with RS |
| `JWT_SECRET` | Yes | Min 32 chars |
| `REDIS_URL` | No | `redis://127.0.0.1:6379`; enables cross-node fan-out |
| `CORS_ORIGINS` | Yes | Comma-separated allowed origins |
| `BREVO_SMTP_LOGIN` | Yes | Brevo SMTP username |
| `BREVO_SMTP_KEY` | Yes | Brevo SMTP password |
| `BREVO_FROM_EMAIL` | No | From address (default `MAIL_USER`) |
| `BREVO_API_KEY` | No | Brevo API key for SMS |
| `MAIL_USER` | No | Gmail fallback user |
| `MAIL_PASS` | No | Gmail fallback app password |
| `OTP_EXPIRY_MINUTES` | No | OTP TTL (default 5) |
| `RATE_LIMIT_MAX` | No | Global API rate limit (default 100) |
| `DISPATCH_TIMEOUT_SECONDS` | No | Driver response timeout (default 120) |
| `APP_ENV` | No | Shown in `/health` response |
| `CINETPAY_API_KEY` | No | CinetPay (pending setup) |
| `CINETPAY_SITE_ID` | No | CinetPay (pending setup) |

---

## 16. Bastion SSH Access to OCI VM

```bash
# 1. Create a managed SSH session via OCI Bastion
oci bastion session create-managed-ssh \
  --bastion-id $(terraform output bastion_id) \
  --target-resource-id <standby_instance_ocid> \
  --target-os-username ubuntu \
  --session-ttl 3600

# 2. Wait for session ACTIVE, then get tunnel command from response
# Example:
ssh -i ~/.ssh/oci_key -p 22 \
  -o ProxyCommand="ssh -i ~/.ssh/oci_key -W %h:%p -p 22 <session_id>@host.bastion.<region>.oci.oraclecloud.com" \
  ubuntu@10.0.2.10
```

---

## 17. Monitoring & Alerting Thresholds

| Check | Command | Alert Condition |
|---|---|---|
| API health | `curl -s https://api.tekeche.com/health` | `status != "ok"` or HTTP != 200 |
| PM2 processes | `pm2 status` | Any process `errored` or `stopped` |
| MongoDB RS | `rs.status()` in mongosh | Any member `state != 1 or 2` |
| Redis replication | `redis-cli INFO replication` | `master_link_status: down` |
| VPN tunnels | OCI Console → IPSec Connection → Tunnels | Any tunnel `DOWN` |
| LB health | OCI Console → LB → Backend sets | Backend set `CRITICAL` |
| On-prem disk | `Get-PSDrive C` | > 85% used |
| OCI boot volume | OCI Console → Block Volumes | > 85% used |

### 17.1 Automatic Rollback Triggers (per CHANGE_MGMT.md)

- `pm2 status` shows `tekeche-api` as `errored` or `stopped`
- `GET /health` returns non-200 or `status != "ok"`
- MongoDB shows `db: "disconnected"` in `/health`
- Any `uncaughtException` in PM2 logs after deployment
