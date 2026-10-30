---
domain: COV
last_updated: 2026-10-30
status: Approved
research_refs: [RS-001]
---

# Requirements: Auditor Coverage Additions

## Overview

RS-001 table (c) compared 25 root-cause classes observed in the 2025-10-30..2026-10-30 incident
window against the `sui-move-auditor` driver (`plugins/sui-ai/agents/sui-move-auditor.md`) and
its six playbooks. Two classes are uncovered (C3 signed-value reinterpretation, C11 governance
capture), six are partial (C6, C7, C8, C9, C12, C20: a related check exists but misses the
mechanism that caused this year's losses), a perpetuals/margin archetype has no playbook
(including the perps side of C17), and C19 (platform/VM) is an advisory context item. Classes
RS-001 marks "covered" get no new requirement here; classes it marks n/a for Move (C22
fee-on-transfer, C23 reentrancy, C25 off-chain cryptography) must not become checks (operator
decision 5 and 6).

These requirements state what the auditor must detect or verify after the change, not how a check
is worded or which grep seeds it. RS-001's check sketches and suggested landing spots are input to
the specs stage, except where an operator decision already fixed the landing spot (the perps
playbook, operator decision 2). A "check" below means the auditor, when run against a matching
target, produces a candidate for the described condition and then applies the driver's evidence
gates before reporting.

**Reading rule (operator decision 8).** The auditor is a prompt-driven agent, so no command can
observe its run-time behaviour directly. Every behavioural requirement below ("the auditor must
identify / verify / report …", "the playbook must require …") is therefore to be read as: *the
driver or playbook text, at a heading the specs stage cites, must instruct the auditor to do
this*, and compliance is decided by two kinds of evidence fixed in REQ-COV-040 through
REQ-COV-042 — the instructing text itself (content-level, checkable by read or grep) and a minimal
vulnerable Sui Move fixture under `tests/fixtures/<class-slug>/` that the check is expected to
flag as a candidate (fixture-level). A behavioural requirement is unmet if either kind of evidence
is missing for it.

Class labels (C3, C6, …) refer to RS-001 table (c). The named incidents are the evidence that the
class caused real losses this year; they are context, not the scope of the check.

## Requirements

**Cross-cutting constraints**

### REQ-COV-001: New checks obey candidate ≠ finding and the evidence gates
Every check added by this cycle must produce candidates, not findings: a reported finding must
pass the evidence and feasibility gates defined in `verification-and-false-positives.md`, and a
pattern miss must not be presented as proof of safety (operator decision 5). Each new check must
also obey the driver's other operating principles: the **absence rule** (a control the check
looks for and does not find is reported as a candidate for a missing control, with the searched
locations named, never silently passed) and the **enumeration-completeness gate** (a check that
iterates over a set — fields, feeds, package versions, collateral assets, governance actions —
must enumerate the whole set and state the count before concluding, so a partial enumeration
cannot be presented as coverage) (operator decision 5). [Updated: 2026-10-30]

### REQ-COV-002: Pattern-only findings capped at Medium
No check added by this cycle may yield a finding above Medium severity on pattern evidence alone;
higher severity requires the code-path or on-chain-configuration evidence the driver's confidence
tiers demand (operator decision 5).

### REQ-COV-003: Classes n/a for Move stay out and are catalogued as such
The change must not add checks for root-cause classes RS-001 marks not applicable to source-level
Move review (reentrancy, fee-on-transfer / reserve sync, token-approval abuse, EVM proxy
mechanics, off-chain TSS flaws); no check is added for these classes. The Move-specific
false-positive catalog in `verification-and-false-positives.md` (§"Move-specific false-positive
catalog") must carry one row per excluded class so the exclusion is auditable: the existing
Reentrancy row is retained, and rows must be added for fee-on-transfer / reserve sync,
token-approval abuse, EVM proxy mechanics and off-chain TSS flaws, each stating why the class
does not apply to Sui Move and what the auditor must not report (operator decision 5).
[Updated: 2026-10-30]

### REQ-COV-004: Checks are generalized patterns
Each new check must be phrased as a generalized mechanism applicable to any Sui Move target of the
matching archetype, not as a single protocol's specifics; incident names may appear only as
illustrative examples.

### REQ-COV-005: Every gap class becomes citable
After the change, each of C3, C6, C7, C8, C9, C11, C12, C20, the perps archetype and the C19
advisory item must be citable to a specific driver section or playbook heading, so that the next
rerun's gap table (REQ-SRC-013) can move the class to "covered" by citing file and heading.

**C3 — Signed-value reinterpretation (uncovered; Aftermath, Sui)**

### REQ-COV-006: Raw-bits stored, signed-read detection
The auditor must identify every numeric field or parameter that is stored or transported in one
numeric domain (unsigned / raw bits) and later interpreted in another (signed, fixed-point with
sign) on a path that reaches a value sink (fee, rate, funding, collateral or balance delta), and
must flag each such field as a candidate.

### REQ-COV-007: Validation at the write boundary
For every candidate from REQ-COV-006, the auditor must verify that a validating constructor or
setter at the write boundary rejects values that are negative or out of the documented range in
the consuming domain, and must report the absence of such validation.

### REQ-COV-008: Caps and comparisons in the consuming domain
For every candidate from REQ-COV-006, the auditor must verify that every cap, bound or comparison
on the value (e.g. a maximum fee) is evaluated in the same numeric domain as the arithmetic that
consumes it, and must report a cap evaluated in a different domain as a candidate bypass.

**C11 — Governance capture (uncovered; BonkDAO, Term, X100, Token of Power, RetoSwap, others)**

### REQ-COV-009: Governance surface triggers governance checks
When the target contains proposal, voting or proposal-execution functionality, the auditor must
run the governance checks REQ-COV-010 through REQ-COV-014 and must record their outcome
individually in the report.

### REQ-COV-010: Voting power from a pre-proposal snapshot
The auditor must verify that voting power is measured from a snapshot taken strictly before the
proposal was created, and must report voting power taken from a live balance (defeatable with
flash-borrowed or same-transaction-acquired tokens).

### REQ-COV-011: Non-zero quorum and proposer threshold
The auditor must verify that the quorum floor is greater than zero and expressed relative to total
voting supply, and that the proposer threshold is greater than zero; a zero or absolute-constant
quorum that total supply can outgrow must be reported.

### REQ-COV-012: Execution delay with a veto path
The auditor must verify that a mandatory delay exists between a proposal passing and its
execution, at least as long as one voting period, and that a guardian or veto path can cancel
during the delay; the absence of either must be reported.

### REQ-COV-013: Restricted executable payload
The auditor must verify that what a passed proposal can execute is restricted to an explicit
allow-list of actions (treasury transfer, package upgrade, parameter change, role grant) and that
each allowed action is itself capability-gated, and must report an unrestricted or
arbitrary-call payload.

### REQ-COV-014: Vote tokens locked for the voting period
The auditor must verify that tokens used to vote cannot be transferred and reused to vote again
within the same voting period, and must report vote-then-transfer-then-vote exposure.

**C6 — Stale package / cross-version state desync (partial; Scallop, BlueMove, Sui)**

### REQ-COV-015: Two live writers of one accounting field
After any storage-layout migration between package versions, the auditor must enumerate every
prior package version's functions that still write a field the current version reads for pricing
or accounting, and must report a field with two live writers across versions even when each
version is internally consistent.

### REQ-COV-016: Immutability declared with a live legacy package
The auditor must detect when a package is made immutable or its upgrade capability is destroyed
while a prior version still holds funds or lacks a pause or version gate, and must report the
"no patch path" condition at no lower than High once the evidence gates pass.

### REQ-COV-017: Legacy entry points reachable from routers
The auditor must verify that public or entry functions of prior package versions cannot be
reached through external routers or aggregators to act on live state, and must report ungated
legacy entry points.

**C7 — Oracle manipulation via thin collateral / recursive borrow / spot read (partial; Tectonic, YieldBlox, Rhea, Makina)**

### REQ-COV-018: Collateral caps justified against liquidity depth
For every collateral asset in a lending target, the auditor must verify that a supply cap and
borrow cap exist and must assess whether the cap is justified against the asset's on-chain
liquidity depth; a listed collateral with no cap, or a cap that cannot be defended against
liquidity depth, must be reported. When no on-chain liquidity data is available to the auditor
(source-only review, unknown deployment, or unreachable chain), the check must not be skipped
silently: every capped collateral must instead be reported as a `needs_review` candidate that
names the cap and states that depth could not be assessed, so the finding stays pattern-only and
is capped per REQ-COV-002. [Updated: 2026-10-30]

### REQ-COV-019: Recursive borrow-and-resupply bounded
The auditor must verify that borrowing an asset and re-supplying the same asset as collateral
within one transaction is forbidden or bounded, and must report an unbounded recursive collateral
loop.

### REQ-COV-020: Single-fill prices rejected
The auditor must verify that the oracle adapter rejects a price set by a single fill (last trade
or thin VWAP) and applies a per-update deviation bound or agreement of at least two independent
sources, and must report an adapter that accepts a single-fill price without a bound.

### REQ-COV-021: Permissionless NAV / price refresh gated
The auditor must identify every permissionless function that refreshes a NAV, AUM or price from
external pool balances and verify that it is paired with a time-weighted or deviation gate; an
ungated refresh must be reported.

**C8 — Oracle misconfiguration (partial; Moonwell, Aave CAPO, Silo, Singularity, Ploutos, Solido)**

### REQ-COV-022: Ratio feeds composed with a base feed
The auditor must classify every consumed price feed as a ratio (exchange-rate) feed or a USD
feed and must report a ratio feed used as a USD price without composition against a base/USD
feed.

### REQ-COV-023: Sanity band on feed changes
The auditor must verify that every feed swap or oracle configuration change is subject to a
sanity band (the new price within a bounded deviation of a secondary reference or the previous
value), and must report configuration changes that can set an arbitrary price in one step.

### REQ-COV-024: Coupled cap parameters move together
Where a feed applies rate-limited growth caps, the auditor must verify that all coupled
parameters (reference ratio, reference timestamp, growth rate) are updated atomically, and must
report parameters that can be desynchronized.

**C9 — Oracle authority / signer set / keeper plausibility (partial; Full Sail, Virtue, Ostium, Aevo)**

### REQ-COV-025: Authority of consumed oracle objects
For every third-party oracle object the target reads (aggregator, price-info object, custom feed),
the auditor must determine who can mutate that object's authority, signer set or queue, and must
verify that the target pins both the expected object identity and the expected authority; an
unpinned feed must be reported. [needs-spike] RS-001 leaves open whether consumers of Pyth
price-info objects need the authority check or only staleness and confidence checks; the
Switchboard mechanism is also unpublished.

### REQ-COV-026: Minimum oracle count and per-update move bound
The auditor must verify that the target requires a minimum count or consensus of independent
oracle inputs and bounds the maximum price move per update unless a second independent feed
agrees, and must report the absence of either.

### REQ-COV-027: Oracle-priced round trip within one staleness window
The auditor must verify that a deposit, price change and withdrawal executed within one staleness
window cannot extract value, through a deposit/withdraw cooldown or a cumulative NAV-deviation
circuit breaker that applies to oracle-priced deposits and redemptions (not only to harvests),
and must report the absence.

### REQ-COV-028: Signed keeper reports carry an on-chain plausibility bound
Where prices arrive as signed keeper or relayer reports, the auditor must verify that the
on-chain acceptance check includes a plausibility bound on the reported value, not only the
signer's identity, and must report signer-only acceptance.

**C12 — Bridge / cross-chain verification (partial; KelpDAO, Liquid, NEAR Intents, others)**

### REQ-COV-029: Verifier quorum of independent operators
The auditor must verify that any attestation, guardian or verifier set that authorizes a
cross-chain message has at least two members and a threshold of at least two independent
operators, and must report a one-of-one configuration at no lower than High once the evidence
gates pass, regardless of operator reputation.

### REQ-COV-030: Replay protection beyond a nonce
The auditor must verify that a validly signed cross-chain packet cannot be replayed or
fabricated against a stale sequence number (uniqueness tied to the full message content, not
only a nonce), and must report nonce-only uniqueness.

### REQ-COV-031: Refund never exceeds deposit
The auditor must verify the invariant that a refund or deposit-resolution callback cannot pay out
more than was deposited, and that a failed or resource-exhausted callback cannot leave a claim in
an authorizable state; violations must be reported.

**Perpetuals / margin archetype (missing; includes C17 perps side and C20)**

### REQ-COV-032: Perps and margin companion playbook
The auditor must ship a companion playbook `defi-perps-and-margin.md` in the driver's companion
directory covering perpetual futures and margin trading (positions, leverage, funding, margin
collateral deltas, integrator or builder fee codes) (operator decision 2).

### REQ-COV-033: Perps playbook load trigger and margin routing
The driver must load the perps playbook whenever the target exposes leveraged positions, funding
rates, margin accounts, or position liquidation, and the load condition must be stated in the
driver's companion-references table (operator decision 2; wiring convention in REQ-REL-002).
Margin targets are routed to BOTH playbooks: a target with margin accounts continues to load
`defi-lending-and-liquidation.md` (which keeps its existing margin-account content, e.g.
self-match and post-trade-health checks) and additionally loads `defi-perps-and-margin.md`; no
margin content moves out of the lending playbook. The driver's "PHASE 8B — PROTOCOL ARCHETYPE
PLAYBOOKS" list must be updated so its "Lending / margin" row names both files, and the
companion-references table must state the same dual load. [Updated: 2026-10-30]

### REQ-COV-034: Funding settled before position or collateral change
The perps playbook must require that accrued funding is settled before any position size, margin
or collateral change on the affected account, and that a change made before settlement is
reported (C17 perps side).

### REQ-COV-035: Funding-rate update permissioned or bounded
The perps playbook must require that funding-rate updates are either permissioned or bounded per
update and per interval, and that a funding-manipulation window (a rate that can be moved and
harvested within one interval) is reported (C20).

### REQ-COV-036: Self-trade on thin books
The perps playbook must require detection of self-match or same-block self-trade on thin order
books or thin virtual liquidity that moves the mark or index price used for settlement, and that
the absence of a self-trade guard or a mark-price smoothing bound is reported (C20).

### REQ-COV-037: Risk-parameter changes re-check open positions
The perps playbook must require that changes to risk parameters (maintenance margin, leverage
cap, collateral weights) are applied with a re-check of existing positions or a transition
window, and that a parameter change that leaves open positions unexaminable or instantly
liquidatable is reported (C20).

### REQ-COV-038: Fee, funding and collateral deltas as signed-value sinks
The perps playbook must treat fee, funding and collateral-delta paths (including integrator or
builder fee codes) as the value sinks for the signed-value checks REQ-COV-006 through
REQ-COV-008, so that the Aftermath-class bug is caught in a perps audit.

**C19 — Platform / VM level (advisory context-gathering item)**

### REQ-COV-039: Pinned framework version and chain lineage recorded
During context gathering, the auditor must record the Sui framework or protocol version pinned by
the target's build files and the chain the target deploys to (noting when it is not Sui mainnet,
e.g. Movement, IOTA, Initia), and must check published security advisories for that version. This
item is advisory context only and must not by itself produce a finding.

**Verification basis for every coverage requirement (operator decision 8)**

### REQ-COV-040: Content-level evidence — instructing text at a cited heading
Every requirement in this file that describes auditor behaviour (REQ-COV-006 through REQ-COV-039)
must be satisfiable by driver or playbook text that instructs the auditor to perform the described
check, located under a heading the spec cites by file and heading; compliance must be decidable by
reading or `grep` of that text alone, without running the auditor. A behavioural requirement
with no cited instructing text is unmet (operator decision 8).

### REQ-COV-041: Fixture-level evidence — compiling vulnerable Move fixture per class
Every new or strengthened class (C3, C6, C7, C8, C9, C11, C12, C20 and the perps archetype
including the C17 perps side) must have a minimal vulnerable Sui Move fixture package under
`tests/fixtures/<class-slug>/` at repository level (outside `plugins/`), with its own `Move.toml`,
that compiles with `sui move build` (Sui CLI 1.81.1 is the reference toolchain) and that the
auditor, run against it, is expected to flag as a candidate for that class. A fixture that does
not compile, or a class without a fixture, leaves the class's requirements unmet. The C19 advisory
item (REQ-COV-039) needs no fixture because it must not produce a finding (operator decision 8).

### REQ-COV-042: Fixture README names class, incident and expected finding
Each fixture directory under `tests/fixtures/<class-slug>/` must contain a short `README.md` that
names the RS-001 class it exercises (C-number and label), the real-world incident it mirrors, the
requirement IDs it is acceptance evidence for, and the expected finding (the condition the auditor
should report and the function or field where it should be reported), so that a reviewer can judge
a run against the fixture without re-deriving the class (operator decision 8).
