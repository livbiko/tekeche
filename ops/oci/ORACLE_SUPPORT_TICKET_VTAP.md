# Oracle Support Ticket — Draft

File this at https://support.oracle.com (or Console → Help menu → "Open a support request", Service Category: **Networking**).

---

## Subject

VTAP CreateVtap fails with 404-NotAuthorizedOrNotFound despite all documented IAM permissions granted (Administrators has tenancy-wide manage all-resources plus explicit vtaps and capture-filters grants)

## Severity

Severity 3 (non-production impact — this is a new isolated build, no service disruption)

## Environment

- **Tenancy OCID**: `ocid1.tenancy.oc1..aaaaaaaaiewffom4npmfpf5yifvheyp5xwynr4ellygcbmhwa2nmgte2riuq`
- **Region**: `uk-london-1`
- **Compartment OCID**: `ocid1.compartment.oc1..aaaaaaaamowm6hhwtteb7uf3c6pytddjjh4xu7thlz5uxyk7ckjbyv6upa5a`
- **VCN OCID**: `ocid1.vcn.oc1.uk-london-1.amaaaaaaoz32urqa6jsq62swqfdvn77kga2zfkoh6ofrtmpfemn3irgtwf7q`
- **Capture filter OCID** (created successfully): `ocid1.capturefilter.oc1.uk-london-1.amaaaaaaoz32urqaemyhovatuskfrms3hphdz2m5ehrro2kunuuuizoumt7q`
- **Source subnet OCID**: `ocid1.subnet.oc1.uk-london-1.aaaaaaaa5mbm6msck5hp4zglna5zgv2axq544qhgklsf2oxfkwuhmrynageq`
- **Target VNIC OCID**: `ocid1.vnic.oc1.uk-london-1.abwgiljtlpitlaimdkohuob4exo23ehmpb6lwwipfjmmx4v7zr4bh6d2amra`
- **Terraform OCI provider**: 8.22.0
- **Last failing OPC request ID**: `da7feed082d9c64b3683f851a8fa1347/6241F0FC4A85BBEEF6E1606A4C485223/937DA5359A5C46355E1EDF63E6EA9D5A` (2026-07-22, ~16:31 UTC)

## Problem Description

We are trying to create a VTAP (Virtual Test Access Point) to mirror traffic from a subnet to a VNIC target within a single, isolated VCN in the compartment above. `CreateVtap` consistently fails with:

```
404-NotAuthorizedOrNotFound, NotAuthorizedOrNotFound
Suggestion: Either the resource has been deleted or service Core Vtap need policy
to access this resource.
Request Target: POST https://iaas.uk-london-1.oraclecloud.com/20160918/vtaps
Service: Core Vtap
Operation Name: CreateVtap
```

The `Administrators` group (which our calling user belongs to) already holds a tenancy-wide `Allow group Administrators to manage all-resources in tenancy` statement. Per your own policy reference documentation ("Details for Verb + Resource-Type Combinations", Core Services → Networking), `CreateVtap` requires:

- `VTAP_CREATE`
- `CAPTURE_FILTER_ATTACH` (in the capture filter's compartment)
- `VCN_ATTACH` (in the VCN's compartment)

We have exhausted three independent, documentation-backed attempts to satisfy this, all producing the **identical** 404 error, byte-for-byte:

1. `Allow service vtap to use virtual-network-family in compartment id <compartment>` — rejected outright at policy-creation time with `400-InvalidParameter, Service {vtap} does not exist`. (This confirmed `vtap` is not a valid service-principal name, consistent with VTAP not being a service-principal-gated resource.)
2. `Allow group Administrators to manage vtaps in compartment id <compartment>` — policy created successfully (`ACTIVE` state, confirmed via `terraform state show`), but `CreateVtap` still 404s identically.
3. `Allow group Administrators to manage capture-filters in compartment id <compartment>` — policy created successfully, but `CreateVtap` still 404s identically.

Notably, the **capture filter itself was created successfully** in the same compartment under the pre-existing `manage all-resources` grant (before either of the two additional explicit policies above existed), so `CAPTURE_FILTER_CREATE` is clearly authorized. Only `CreateVtap` itself fails, and it fails identically regardless of which of the three policy combinations above is in place.

## Question for Support

Given that (a) a tenancy-wide `manage all-resources` grant is already in place, (b) two additional explicit resource-type grants (`vtaps`, `capture-filters`) have been added and confirmed active, and (c) the error is completely unchanged across all three states — is this a genuine bug or provisioning gap in VTAP support for this tenancy/region (`uk-london-1`), rather than an IAM policy issue? Please advise whether VTAP is fully enabled for this tenancy, and if there is any additional internal allowlisting or service-limit step required beyond standard IAM policy.

## Steps to Reproduce

1. In the compartment/VCN above, a capture filter already exists (OCID above).
2. Attempt `POST /20160918/vtaps` (or `oci network vtap create` / Terraform `oci_core_vtap`) with:
   - `compartmentId` = compartment OCID above
   - `vcnId` = VCN OCID above
   - `captureFilterId` = capture filter OCID above
   - `sourceId` = subnet OCID above, `sourceType` = SUBNET
   - `targetId` = VNIC OCID above, `targetType` = VNIC
3. Observe 404-NotAuthorizedOrNotFound as shown above.

## Additional Context

- Two earlier failed attempts (2026-07-21) produced the same error text; their specific OPC request IDs were not retained, but occurred within a few hours of each other against the same tenancy/compartment/API operation, so your logs should correlate them by timestamp if needed.
- We are not requesting a policy syntax review — we believe the policy statements above are syntactically correct per your own documentation, and are asking whether this is a platform-side issue.
