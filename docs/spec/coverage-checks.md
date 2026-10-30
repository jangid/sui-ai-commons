---
status: Approved
last_updated: 2026-10-30
requires: [REQ-COV-001, REQ-COV-002, REQ-COV-003, REQ-COV-004, REQ-COV-005, REQ-COV-006, REQ-COV-007, REQ-COV-008, REQ-COV-009, REQ-COV-010, REQ-COV-011, REQ-COV-012, REQ-COV-013, REQ-COV-014, REQ-COV-015, REQ-COV-016, REQ-COV-017, REQ-COV-018, REQ-COV-019, REQ-COV-020, REQ-COV-021, REQ-COV-022, REQ-COV-023, REQ-COV-024, REQ-COV-025, REQ-COV-026, REQ-COV-027, REQ-COV-028, REQ-COV-029, REQ-COV-030, REQ-COV-031, REQ-COV-039, REQ-COV-040]
---

# Coverage Checks — Landing Spots and Check Contracts

## Context

RS-001 table (c) left eight classes uncovered or partial and one advisory item. The requirements
(REQ-COV-006 … 031, 039) say what the auditor must detect; this spec decides, per class, **where
the instructing text lands** (file and exact heading) and **what the text must contain** (the
check contract). It also fixes the cross-cutting rules every new check obeys (REQ-COV-001 … 005)
and the content-level evidence rule (REQ-COV-040). Perps-archetype checks (REQ-COV-032 … 038)
are in `perps-playbook.md`; fixtures (REQ-COV-041, 042) in `fixtures.md`.

The auditor is text. "Check" below means a bullet (or checkbox) under a heading that instructs
the agent; the implementer writes the bullet, this spec is the acceptance contract for it. Check
wording, grep seeds and incident parentheticals are illustrative here and final in the implement
stage, except where marked **(fixed)**.

## Design

### Check contract schema (applies to every CHK-* below)

Each check is specified with these fields; the implementer's bullet must make each field
recoverable by reading it:

| Field | Meaning |
|---|---|
| **Lands at** | File → exact heading text (existing, renamed or new). Headings are the citation unit for REQ-COV-005 and REQ-COV-040. |
| **Trigger** | When the auditor runs the check: the playbook's load condition, or a grep/feature condition stated in the bullet ("when the target has …"). |
| **Enumerate** | The set the check walks, with the enumeration-completeness gate (count N found vs M analysed, stated in the report). |
| **Invariant** | What must hold for every element; a violation is a candidate. |
| **Absence** | What the auditor reports when the expected control is not found anywhere (missing-control candidate naming the locations searched). |
| **Evidence gate** | Signals required to move the candidate past `needs_review`; always the two-gate feasibility check for High/Critical. |
| **Severity cap** | Max on pattern-only evidence (always Medium, REQ-COV-002); the tier at which the stated floor, if any, applies. |
| **Carve-outs** | Conditions under which the pattern is not a finding (false-positive discipline). |
| **Fixture** | The `tests/fixtures/<slug>` that must exhibit the violation (see `fixtures.md`). |

**Style constraints (fixed):** bold lead-in phrase; ≤ 6 lines per bullet in the driver, ≤ 8 in a
playbook; grep seeds in backticks; the invariant stated as a sentence containing "must"; the
carve-out introduced by "Not a finding when" or "Do not report"; incident names only inside
parentheses as examples (REQ-COV-004); no protocol-specific function names as the check's
subject.

### Cross-cutting rules (REQ-COV-001, 002, 004, 005)

- **Candidate ≠ finding; evidence gates.** Every CHK-* bullet must either state its severity
  cap inline ("pattern-only ⇒ max Medium") or sit under a heading whose preamble says so for the
  whole block. Decision: the perps playbook and the new oracle section carry a one-line preamble;
  driver checkboxes state it inline where a floor exists (CHK-C6-2, CHK-C12-1) and inherit the
  Phase 9 gate otherwise. Rationale: the driver already routes every finding through Phase 9;
  repeating the cap on each of ~20 new driver lines would bloat the file without changing
  behaviour.
- **Absence rule.** Every check whose invariant is "a control exists" must say what to report
  when it is not found and where to look (the bullet names the grep seeds *and* the modules /
  function families to read), never "if present, verify".
- **Enumeration-completeness gate.** Every check over a set names the set and requires the N/M
  count in the report.
- **Generalized patterns.** The subject of each bullet is a mechanism ("a numeric field stored
  in one domain and read in another"), never a protocol or a function name from an incident.
- **Citability (REQ-COV-005).** After the change, the table in §Class inventory below is
  reproduced (file → heading) in the next rerun's gap table; every heading named there must
  exist verbatim in the file after implementation (verified by `grep -F`).

### Class inventory (fixed landing spots)

| Class | Lands at | Checks | Fixture slug |
|---|---|---|---|
| C3 | driver → `### 5.3a High-signal correctness greps (cheap, high severity)`; sinks in `defi-perps-and-margin.md` → `## Fees, funding and collateral deltas as signed-value sinks` | CHK-C3-1..3 | `c03-signed-value-reinterpretation` |
| C6 | driver → `### 6.14 Package Upgrade Safety` | CHK-C6-1..3 | `c06-cross-version-state-desync` |
| C7 | `defi-lending-and-liquidation.md` → `## Market creation & configuration validation` (sub-block **Collateral listing quality**, CHK-C7-1..2) and `## Oracle staleness & price representability` (CHK-C7-3); driver → `### 7.2 Oracle & Price Manipulation` (CHK-C7-4, read by every audit) | CHK-C7-1..4 | `c07-thin-collateral-recursive-borrow` |
| C8 | `defi-lending-and-liquidation.md` → `## Oracle staleness & price representability` | CHK-C8-1..3 | `c08-oracle-ratio-feed-misconfig` |
| C9 | `sui-native-pitfalls.md` → `## Oracle integrations (Pyth / Switchboard / custom feeds)` (new); driver → `### 7.2 Oracle & Price Manipulation` (one bullet that explicitly loads `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/sui-native-pitfalls.md`); driver → COMPANION REFERENCES table, `sui-native-pitfalls.md` row's load condition gains "oracle / third-party price-object consumption" | CHK-C9-1..4 | `c09-oracle-authority-unpinned` |
| C11 | driver → `### 6.8 Governance, Voting & Weight Safety` (renamed) | CHK-C11-0..5 | `c11-governance-capture` |
| C12 | `sui-native-pitfalls.md` → `## Cross-chain / bridge / ZK` | CHK-C12-1..3 | `c12-bridge-single-verifier` |
| C19 | driver → `## PHASE 1 — CONTEXT GATHERING` (new step 10) | CHK-C19-1 | none (exempt) |
| n/a classes | `verification-and-false-positives.md` → `## Move-specific false-positive catalog ("looks vulnerable, is safe")` | CAT-1..4 | none |

Landing-spot rationale (REQ-REL-013): C3, C6, C11 and C19 are Move/package/governance mechanics
that any target can exhibit → driver. C7 and C8 are lending-market configuration → lending
playbook (they only make sense where collateral and feeds exist) — except CHK-C7-4, whose
mechanism (permissionless NAV/AUM/price refresh; Makina is a share/vault incident) is not
lending-specific and whose requirement REQ-COV-021 is not scoped to lending targets → driver
7.2, which every audit reads. C9 and C12 concern third-party objects (oracle packages, bridge
attestations) → `sui-native-pitfalls.md`, which already holds the cross-chain section. That file
is **not** loaded for every audit: its companion-table load condition (randomness,
signatures/replay, cross-chain, hard platform limits, Kiosk/Publisher, denylist, fixed-point
libs, deployed-package/bytecode review) never mentions oracles, so the change set **amends that
load condition** to add "oracle / third-party price-object consumption" (edit listed in
`release-wiring.md` §Change-set inventory and checked by
`sui_native_load_condition_mentions_oracle`), and the driver's 7.2 bullet is an explicit load
instruction for the file, not a bare pointer. The new section opens with an "applies when" line
so targets that load the file for another reason skip it. RS-001's suggestions were followed in
every case except the CHK-C7-4 placement.

### C3 — Signed-value reinterpretation (REQ-COV-006, 007, 008)

Lands at driver → `### 5.3a High-signal correctness greps (cheap, high severity)`, **one to
three** new bullets; the first has the lead-in **Raw-bits stored, signed-read (domain
reinterpretation).** and any further bullets (write-boundary validation, consuming-domain caps)
follow it directly, so the ≤ 6-line driver limit holds per bullet. The perps playbook names the
sinks (PB-5 in `perps-playbook.md`) and points at the first bullet.

- **CHK-C3-1 (REQ-COV-006) — identify the candidates.** Trigger: any target (driver bullet).
  Enumerate: every numeric field/parameter that is written in one domain (unsigned integer / raw
  bits) and later consumed in another (signed, sign-carrying fixed-point) on a path to a value
  sink (fee, rate, funding, collateral or balance delta). Grep seeds (illustrative):
  `i64|i128|I64|I128|ifixed|IFixed|from_raw|from_bits|is_negative|sign|neg`. Invariant: a field's
  write domain must equal its read domain, or the conversion must be explicit and validated.
  Absence: if signed types exist and no validating conversion is found, report the field.
  Evidence gate: traced path constructor → sink = `likely`. Cap: pattern-only ⇒ Medium.
  Carve-out: not a finding when the field is never read in a signed domain (pure unsigned
  pipeline) or the signed decoder itself aborts on the sign bit.
- **CHK-C3-2 (REQ-COV-007) — validation at the write boundary.** For each CHK-C3-1 candidate,
  the constructor/setter must reject negative or out-of-range values *in the consuming domain's
  terms* (e.g. `assert!(!is_negative(v))`, `assert!(v <= MAX_FEE)`). Absence is the finding;
  name the constructor. Carve-out: a `public(package)` constructor whose only callers already
  validate (trace them; "callers validate" without a trace is `needs_review`).
- **CHK-C3-3 (REQ-COV-008) — caps compared in the consuming domain.** For each candidate, every
  cap/bound/comparison on the value must be evaluated in the same domain as the arithmetic that
  consumes it; a cap evaluated as unsigned on a value later read as signed is a bypass
  candidate (a huge unsigned value passes `<= MAX` after wrapping negative, or fails it while
  the signed read sees a small negative). Evidence gate for High: algebraic example with the
  type's bit width (two's-complement value that passes the cap and reads negative).

### C6 — Cross-version state desync and no-patch-path (REQ-COV-015, 016, 017)

Lands at driver → `### 6.14 Package Upgrade Safety`, three new checkboxes placed directly after
the existing **Stale-package attack surface** item (they extend it).

- **CHK-C6-1 (REQ-COV-015) — two live writers of one accounting field.** Trigger: the target
  has more than one published version *or* a storage-layout migration (field → dynamic field /
  escrow object) is visible in source or `Move.lock` history. Enumerate: every field the
  current version reads for pricing or accounting (`reserve_*`, `total_*`, `supply`, `index`)
  and, for each, every function in every prior version that writes it. Invariant: each such
  field must have exactly one live writer lineage, or the prior writers must be version-gated.
  Absence/limit: when prior-version source is unavailable, say so and tag `[ZD-EXT-UNVERIFIED]`;
  do not conclude "single writer". Cap: Medium without the prior-version source; `likely`/High
  with both writers read. Carve-out: prior version provably disabled by a version gate on *every*
  writer (cite each assert) — not merely "deprecated".
- **CHK-C6-2 (REQ-COV-016) — immutability declared with a live legacy package.** Grep seeds:
  `make_immutable|burn.*UpgradeCap|UpgradeCap.*burn|destroy.*UpgradeCap`. Invariant: a package
  may be made immutable only if no prior version holds funds and every prior version is pause- or
  version-gated. Severity (fixed): **no lower than High once the two-gate feasibility check
  passes** (reachability: the legacy entry point is callable; math-bounds: funds or pricing
  state is live in it). Pattern-only (immutability call seen, legacy state not confirmed) ⇒
  Medium with `needs_review`. Carve-out: immutability of a package with no shared state and no
  balances (pure library).
- **CHK-C6-3 (REQ-COV-017) — legacy entry points reachable from routers.** Enumerate: every
  `public`/`entry` function of prior versions that mutates shared state. Invariant: each must be
  unreachable for live state (version gate, pause, or removed object type) including via
  external routers/aggregators that address packages by ID. Absence: ungated legacy entry point
  = candidate. Carve-out: a function whose shared-object parameter type no longer exists in any
  live object.

### C7 — Thin collateral, recursive borrow, spot read (REQ-COV-018 … 021)

CHK-C7-1 and -2 land in `defi-lending-and-liquidation.md` under
`## Market creation & configuration validation` as a bolded sub-block **Collateral listing
quality** (two bullets); CHK-C7-3 under `## Oracle staleness & price representability`;
CHK-C7-4 lands in the driver → `### 7.2 Oracle & Price Manipulation`, which every audit reads
(a vault target that loads only `defi-shares-and-vaults.md` would otherwise never see it).

- **CHK-C7-1 (REQ-COV-018) — caps justified against liquidity depth.** Enumerate: every listed
  collateral asset (N) with its supply cap and borrow cap. Invariant: both caps exist and are
  defensible against the asset's on-chain liquidity depth (the lending twin of the AMM
  playbook's "manipulation-cost estimation"). Three outcomes (fixed): (a) no cap → candidate,
  Medium+; (b) cap present and depth known → judge; (c) **depth unknown (source-only review,
  unknown deployment, unreachable chain) → every capped collateral is reported as a
  `needs_review` candidate naming the cap and stating that depth could not be assessed —
  never skipped silently.** Cap: (c) is pattern-only ⇒ Medium. Carve-out: isolated-collateral
  mode where the asset cannot be borrowed against other markets *and* its cap is bounded by a
  formula over its own pool.
- **CHK-C7-2 (REQ-COV-019) — recursive borrow-and-resupply bounded.** Invariant: borrowing an
  asset and supplying the same asset as collateral within one transaction is forbidden or
  bounded (per-asset loop count, per-tx exposure snapshot). Grep seeds: the `borrow`/`supply`
  pair taking the same `Coin<T>` type; absence of a same-asset check. Cross-reference the
  driver's **Per-call vs. per-transaction limits** (Phase 7.5). Cap: Medium until a PTB
  sequence is written (`likely` ⇒ High).
- **CHK-C7-3 (REQ-COV-020) — single-fill prices rejected.** Enumerate: every oracle adapter /
  price source. Invariant: a price set by a single fill (last trade, thin VWAP) is rejected, or a
  per-update deviation bound / ≥ 2 independent sources applies. Carve-out (fixed, from the
  playbook's known-good list): spot price used for the *seize* leg alongside EMA/TWAP for
  *eligibility* is intentional — only an unbounded manipulable price in the eligibility path is
  the finding.
- **CHK-C7-4 (REQ-COV-021) — permissionless NAV/price refresh gated.** Lands at driver 7.2 as
  one bullet, lead-in **Permissionless NAV/AUM/price refresh**, placed directly before the
  CHK-C9 load bullet. Trigger: any target (grep hit). Enumerate: every permissionless function
  that refreshes NAV/AUM/price from external pool balances (grep seeds
  `update_nav|update_aum|refresh_price|sync_price|poke`). Invariant: paired with a TWAP or
  deviation gate. Absence = candidate (name the function). Cap: pattern-only ⇒ Medium (inherits
  Phase 9). Carve-out: a refresh gated by a capability whose holder is enumerated in Phase 2.

### C8 — Oracle misconfiguration (REQ-COV-022, 023, 024)

Lands at `defi-lending-and-liquidation.md` → `## Oracle staleness & price representability`,
three bullets after the existing **No unpriced-asset $1 assumption** item.

- **CHK-C8-1 (REQ-COV-022) — ratio feeds composed with a base feed.** Enumerate: every consumed
  feed, classified *ratio* (LST/base, wrapped/underlying exchange rate) or *USD*. Invariant: a
  ratio feed is multiplied by a base/USD feed before use as a price. Report a ratio feed
  consumed as USD. Cap: Medium pattern-only; `likely` once the health-path read is traced.
- **CHK-C8-2 (REQ-COV-023) — sanity band on feed changes.** Enumerate: every feed-swap /
  oracle-config setter. Invariant: the new price must lie within a bounded deviation of a
  secondary reference or the previous value, or the change is time-locked with the band checked
  at activation. Absence = a one-step arbitrary price = candidate (blast-radius finding; the
  trust-model qualifier applies — admin-only trigger does not dismiss it, see the driver's
  **Trust qualification**).
- **CHK-C8-3 (REQ-COV-024) — coupled cap parameters move together.** Where rate-limited growth
  caps exist, enumerate the coupled parameters (reference ratio, reference timestamp, growth
  rate). Invariant: one setter updates all of them atomically; separately settable parameters =
  desync candidate. Carve-out: a single struct-replacing setter (but then the lending playbook's
  **Config updates that clobber runtime state** applies — cite both).

### C9 — Oracle authority, consensus, round trip, keeper plausibility (REQ-COV-025 … 028)

Lands at `sui-native-pitfalls.md` as a **new section** `## Oracle integrations (Pyth /
Switchboard / custom feeds)`, inserted after `## Cross-chain / bridge / ZK`, with a preamble
line "Applies when the target reads any price object it does not itself produce. Pattern-only
candidates here are `needs_review` ⇒ max Medium." Plus one bullet in the driver →
`### 7.2 Oracle & Price Manipulation`: **Consumed-feed authority and plausibility** → an
**explicit load instruction** (fixed intent): "When the target reads any price object it does
not itself produce, load `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/sui-native-pitfalls.md`
and run its `## Oracle integrations (Pyth / Switchboard / custom feeds)` section." No duplicate
content; keeps 7.2 a question list; the bare filename never appears without the full path
(operator decision 9). The companion table's `sui-native-pitfalls.md` row also gains "oracle /
third-party price-object consumption" in its load condition (edit listed in
`release-wiring.md`), so the file is loaded by companion routing as well as by this bullet.

- **CHK-C9-1 (REQ-COV-025) — authority of consumed oracle objects.** Enumerate: every
  third-party price object type the target reads (N). For each, the auditor must (i) determine
  from the oracle package's source who can mutate the object's authority / signer set / queue,
  and (ii) verify the target pins the expected *object identity* and, where the object type has
  one, the expected *authority*. The contract is provider-specific; the bullet carries this
  table (fixed content, wording free):

  | Provider object | Who can change what feeds it (per source read 2026-10-30) | Consumer must pin | Authority check? |
  |---|---|---|---|
  | Pyth `PriceInfoObject` | No per-object mutable authority. Updates enter only through `pyth::update_single_price_feed`, which consumes a hot-potato produced from a Wormhole-verified VAA whose emitter passes `state::is_valid_data_source` (governance-controlled); the write path calls `state::assert_latest_only`. Source: `pyth-crosschain/target_chains/sui/contracts/sources/pyth.move` `[ZD-PROD-SOURCE]`. | The **feed identity**: `price_info::get_price_identifier(...)` equals the expected feed ID (Pyth's own Sui docs show `assert!(price_id == expected, E_INVALID_ID)`), and the object's type originates from the canonical Pyth package address. The update path checks identifier *match between update and object* but does **not** check the object against the registry, so a homonymous or attacker-created object is the consumer's problem. | **No** separate authority pin (there is none to pin). Staleness (`get_price_no_older_than`, note `abs_diff` treats future timestamps as age) and confidence-interval checks are required instead. |
  | Switchboard On-Demand `Aggregator` | Has a per-feed `authority` (set at `Aggregator.initTx`) and a `queue` whose oracle set is governed per queue; oracles' responses are accepted when signed by keys registered in the queue. Feed-level configs (`minSampleSize`, `maxStalenessSeconds`, variance) are set by the authority. `current_result()` does **not** gate on age. Source: Switchboard Sui README + docs.sui.io oracle page `[ZD-DOC]`; the Move `schemas/`/`actions/` modules were **not read** (see S-1). | Aggregator `object::id` **and** the expected `queue` ID (canonical mainnet queue) **and** the expected `authority`; consumer-side `min_sample_size`, `max_staleness`, variance read from the result, and its own age check against `Clock`. | **Yes** — a mutable authority/queue is exactly the Full Sail surface. |
  | Custom / in-house feed object | Read the module: find every function that writes `price`, `authority`, `signers`, `threshold`. | Object ID + every writer capability-gated and the cap holder enumerated in Phase 2. | Yes. |

  Invariant: for each consumed object type, the pinned identity (and authority where one exists)
  is asserted in every read path (absence rule — one unpinned read path is a candidate).
  Evidence gate: `likely` requires the oracle package source read (`[ZD-PROD-SOURCE]`); without
  it, the finding stays `needs_review`. Carve-out: Pyth consumers are **not** reported for
  lacking an authority pin; they are reported only for a missing feed-ID pin, missing
  originating-package check, missing staleness check, or missing confidence check.

  **[high-uncertainty] Spike S-1 (bounded, ≤ 5 tool calls, implement stage).** Unverified
  assumption: Switchboard's Sui `Aggregator` exposes `authority` and `queue` as readable fields
  and has authority-gated setters (`set_authority`, `set_configs`) in `on_demand/sources/actions/`.
  Spike: read `on_demand/sources/schemas/aggregator.move` and the `actions/aggregator_*` modules
  in `github.com/switchboard-xyz/sui`; record field names, the setter guards, and the
  `CurrentResult` accessors. Fallback if the assumption is wrong (no readable authority): the
  Switchboard row collapses to "pin aggregator ID + queue ID + consumer-side staleness/variance",
  i.e. the Pyth shape plus queue pinning; the check contract and fixture are unchanged (the
  fixture pins neither ID nor queue, which is a violation under either outcome).
- **CHK-C9-2 (REQ-COV-026) — minimum oracle count and per-update move bound.** Invariant: the
  target requires a minimum count / consensus of independent inputs **and** bounds the maximum
  price move per update unless a second independent feed agrees. Both absent = candidate; one
  absent = candidate naming which. Carve-out: an aggregator whose *own* `min_sample_size` is
  read and asserted by the consumer counts as the minimum-count control.
- **CHK-C9-3 (REQ-COV-027) — oracle-priced round trip within one staleness window.** Invariant:
  deposit → price change → withdraw inside one staleness window cannot extract value; required
  control is a deposit/withdraw cooldown or a cumulative NAV-deviation circuit breaker that
  applies to oracle-priced deposits and redemptions, not only harvests (this generalizes the
  driver's 7.2 "cumulative NAV deviation circuit breaker"). Evidence gate for High: a concrete
  sequence with the window length and the price move needed.
- **CHK-C9-4 (REQ-COV-028) — signed keeper reports carry a plausibility bound.** Trigger: prices
  arrive as signed keeper/relayer payloads verified on-chain. Invariant: acceptance checks a
  plausibility bound on the value (deviation from previous / from a second feed), not signer
  identity alone. Cross-reference the existing **Signatures validated against live mutable
  policy** bullet (distinct: that one is about the signer set, this one about the payload
  value).

### C11 — Governance capture (REQ-COV-009 … 014)

Lands at driver: rename `### 6.8 Weight & Governance Safety` → `### 6.8 Governance, Voting &
Weight Safety` **(fixed)**; keep the five existing checkboxes; prepend a trigger line and add
five checkboxes.

- **CHK-C11-0 (REQ-COV-009) — trigger and per-check reporting.** Trigger line (fixed content):
  "When the target has proposal, voting or proposal-execution functionality (grep
  `propose|vote|cast|quorum|execute_proposal|timelock`), run every governance item below and
  record each outcome individually in the findings or the verified-clean list." Rationale:
  REQ-COV-009 requires individual recording; the driver already has a findings list and a
  "Verified clean" list in Phase 9, so the governance block binds to those rather than
  inventing a new report section.
- **CHK-C11-1 (REQ-COV-010) — snapshot before proposal.** Invariant: voting power is read from
  a snapshot (balance checkpoint, locked-stake record, epoch) taken strictly before proposal
  creation; a live `balance::value` / current stake read in `vote` is a flash-loan-defeatable
  candidate. Cross-reference Phase 1.1 (quorum/threshold state is flash-loan-reachable).
- **CHK-C11-2 (REQ-COV-011) — quorum and proposer threshold.** Invariant: quorum floor > 0,
  expressed relative to total voting supply (not an absolute constant total supply can outgrow);
  proposer threshold > 0. Report zero or absolute-constant quorum. Carve-out: an absolute quorum
  on a fixed-supply token with no mint path (cite the `TreasuryCap` disposition).
- **CHK-C11-3 (REQ-COV-012) — execution delay with veto.** Invariant: a mandatory delay ≥ one
  voting period between pass and execute, and a guardian/veto path that can cancel during it.
  Either absent = candidate (name which). Note the existing 6.5 timelock item is for admin
  actions; this one is for passed proposals.
- **CHK-C11-4 (REQ-COV-013) — restricted executable payload.** Invariant: the executable payload
  is an explicit allow-list of actions (treasury transfer, package upgrade, parameter change,
  role grant), each itself capability-gated. Move has no arbitrary call, so the Move shape of
  "arbitrary payload" is (fixed): a proposal that carries a generic
  `(target: address, amount: u64)` transfer, an `UpgradeTicket` authorisation without policy
  bound, or a cap object handed to the executor. Report those.
- **CHK-C11-5 (REQ-COV-014) — vote tokens locked for the voting period.** Invariant: tokens
  that voted cannot be transferred and re-voted within the same period (lock object, `key`-only
  vote receipt bound to the balance, or snapshot semantics from CHK-C11-1 that make re-voting
  moot). Carve-out: snapshot voting (CHK-C11-1 satisfied) makes this item pass by construction —
  say so rather than reporting.

### C12 — Bridge verification (REQ-COV-029, 030, 031)

Lands at `sui-native-pitfalls.md` → `## Cross-chain / bridge / ZK`, three bullets after the
existing **Fake bridge package object** item.

- **CHK-C12-1 (REQ-COV-029) — verifier quorum of independent operators.** Enumerate: every
  attestation / guardian / verifier set that authorises a message (N). Invariant: size ≥ 2 and
  threshold ≥ 2 independent operators. Severity (fixed): a 1-of-1 configuration is **no lower
  than High once the two-gate check passes** (reachability: the set authorises value-moving
  messages; math-bounds: the value reachable with one key), **regardless of operator
  reputation** — reputation is `[ZD-DOC]`-grade and cannot dismiss. Pattern-only (threshold
  constant seen, path not traced) ⇒ Medium. Carve-out: a 1-of-1 set that only authorises
  non-value-moving metadata, or a configuration object the consumer verifies against a
  governance-controlled registry that enforces ≥ 2.
- **CHK-C12-2 (REQ-COV-030) — replay protection beyond a nonce.** Invariant: uniqueness is tied
  to the full message content (hash of the signed payload stored as nullifier), not a nonce
  alone; a stale sequence number must not let a validly signed packet be replayed or a fabricated
  one accepted. Extends the existing **Nonce replay** signature bullet to the bridge case; the
  new bullet must cross-reference it rather than repeat it.
- **CHK-C12-3 (REQ-COV-031) — refund never exceeds deposit; failed callbacks are inert.**
  Invariant: any refund / deposit-resolution path pays `≤ deposited`, and a failed or
  resource-exhausted callback (abort, child-object cap, event-size cap) cannot leave a claim in
  an authorisable state. Cross-reference the **Hard platform limits** section for the
  resource-exhaustion mechanism.

### C19 — Platform / VM advisory (REQ-COV-039)

Lands at driver → `## PHASE 1 — CONTEXT GATHERING`, as **numbered step 10** after the
fork-ancestry sweep (step 9), before `### 1.1`.

- **CHK-C19-1 (fixed semantics).** Record (a) the Sui framework / protocol version pinned by
  `Move.toml` / `Move.lock` (or the implicit framework version of the toolchain), (b) the chain
  the target deploys to, noting explicitly when it is not Sui mainnet (Movement, IOTA, Initia and
  other Move-derived VMs have separate advisory streams), and (c) a check of published security
  advisories for that version. The step must end with the sentence (fixed intent): "Advisory
  context only — this step never produces a finding by itself." Rationale for Phase 1 rather
  than 6.14: it is context gathering; 6.14 items are checkboxes that produce findings.

### n/a classes — false-positive catalog rows (REQ-COV-003)

Lands at `verification-and-false-positives.md` → `## Move-specific false-positive catalog
("looks vulnerable, is safe")`, four new rows appended to the existing table (the Reentrancy row
is retained unchanged). Each row has the table's **three** columns (Pattern | Why usually safe |
Bug condition); the `CAT-n` IDs in the first column below are **spec-only citation handles**
for `fixtures.md` and the PR table and are **not** written into the target table. Contents
(fixed intent, wording free):

| ID | Pattern | Why usually safe (Move) | Bug condition / what not to report |
|---|---|---|---|
| CAT-1 | Fee-on-transfer / reserve `sync`/`skim` mismatch (C22) | `Coin<T>`/`Balance<T>` amounts are exact; no transfer hooks | (n/a — do not import EVM deflationary-token checks; the real Sui cousin is the donation vector in `defi-shares-and-vaults.md`) |
| CAT-2 | Token-approval abuse (EVM `approve`/`permit` drains) | No allowance model; objects move by ownership | (n/a — do not report "unlimited approval"; the Sui analogue is a `store`-able cap or receipt — covered by Phase 6.2) |
| CAT-3 | EVM proxy / delegatecall / implementation hijack | No delegatecall; upgrades go through `UpgradeCap` policy | (n/a — do not report proxy-storage-collision or `initialize`-on-implementation; report `UpgradeCap` custody and stale-package issues under 6.14 instead) |
| CAT-4 | Off-chain cryptography / TSS library flaws (C25) | Not Move code | (n/a — note as out of scope in the report's context section; do not fabricate a contract finding) |

Decision: rows rather than a separate "excluded classes" section, because the catalog is the
file the driver already loads before finalising and a rerun can `grep` the class labels there.

### Content-level evidence rule (REQ-COV-040)

For every CHK-* above, compliance is decided by reading or `grep` of the cited file and heading:
the heading exists verbatim, and under it a bullet satisfies the check contract's fields. The
implementer must add to the PR description a table `CHK-ID | file | heading | first words of the
bullet`, which is the artifact the verify stage greps. No auditor run is part of compliance.

### Interaction with other specs

- `perps-playbook.md` owns PB-1..5 and the heading `## Fees, funding and collateral deltas as
  signed-value sinks` that CHK-C3 relies on for the perps sink list.
- `fixtures.md` maps every CHK-* (except CHK-C19-1) to a slug.
- `release-wiring.md` lists the exact files touched here as plugin content (version bump).

## Verification

### Automated

Grep-level checks against the plugin files after implementation (run from the repo root;
`D=plugins/sui-ai/agents/sui-move-auditor.md`, `P=plugins/sui-ai/agents/sui-move-auditor`):

- `headings_exist_verbatim`: `grep -F` for each heading in §Class inventory returns exactly one
  line in the named file, including the renamed `### 6.8 Governance, Voting & Weight Safety`,
  the new `## Oracle integrations (Pyth / Switchboard / custom feeds)`, and the old heading
  `### 6.8 Weight & Governance Safety` returns zero lines.
- `c3_bullets_in_5_3a`: between `### 5.3a` and `### 5.4`, a bullet whose bold lead-in contains
  "signed" exists, and that bullet together with at most two bullets directly following it
  mentions "write boundary" (or "constructor") and "same domain" (or "consuming domain");
  one to three new bullets in total.
- `c6_three_items_in_6_14`: between `### 6.14` and `### 6.15`, three new `- [ ]` items match
  respectively `writer`, `make_immutable|UpgradeCap`, and `router|aggregator|legacy entry`.
- `c6_floor_stated`: the immutability item contains "High".
- `c7_in_market_creation`: in `$P/defi-lending-and-liquidation.md`, between
  `## Market creation & configuration validation` and the next `## ` heading, the text contains
  "Collateral listing quality", `needs_review` and "re-supply" (or "resupply").
- `c7_c8_in_oracle_staleness`: between `## Oracle staleness & price representability` and the
  next `## ` heading, the text contains each of: "single fill", "ratio", "sanity band" (or
  "deviation"), "atomically" (or "together").
- `c7_4_refresh_in_7_2`: between `### 7.2` and `### 7.3` in `$D`, a bullet contains "refresh"
  and ("TWAP" or "deviation").
- `c7_depth_unknown_path`: the caps bullet contains "could not be assessed" (or "depth unknown")
  and `needs_review`.
- `c9_section_and_table`: new section exists in `$P/sui-native-pitfalls.md` with a table having
  rows containing `PriceInfoObject` and `Aggregator`; the Pyth row contains
  `get_price_identifier` and does **not** instruct pinning an authority; the preamble contains
  "max Medium".
- `c9_driver_load_instruction`: between `### 7.2` and `### 7.3` in `$D`, a line contains the
  full path `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/sui-native-pitfalls.md` and the word
  "load" (or "Load"); no bare `sui-native-pitfalls.md` mention without that path on the same
  line (operator decision 9).
- `sui_native_load_condition_mentions_oracle`: `grep -iE 'sui-native-pitfalls\.md.*\|.*oracle' $D`
  returns exactly one line — the COMPANION REFERENCES row.
- `c11_trigger_and_five_items`: between `### 6.8` and `### 6.9`, a trigger line contains
  "record each outcome" (or "individually"), and five new `- [ ]` items match `snapshot`,
  `quorum`, `delay|timelock` + `veto|guardian`, `allow-list|allowlist`, `lock|re-vote`.
- `c12_three_bullets`: under `## Cross-chain / bridge / ZK`, bullets matching `threshold`
  + `High`, `message hash|full message|nullifier`, and `refund` exist.
- `c19_step_10`: `$D` has a line beginning `10.` before `### 1.1` containing "framework" and
  "advisor", and the phrase "never produces a finding" (or "Advisory context only").
- `catalog_rows_added`: the catalog table in `$P/verification-and-false-positives.md` has four
  new rows matching `fee-on-transfer|Fee-on-transfer`, `approval`, `proxy|delegatecall`, and
  `TSS|off-chain crypto`; the `Reentrancy` row is still present.
- `no_incident_as_subject`: no new bullet *begins* its bold lead-in with a protocol name
  (Aftermath, BlueMove, Full Sail, Tectonic, Ostium, BonkDAO, KelpDAO…); names appear only in
  parentheses.
- `style_lengths`: each new driver bullet ≤ 6 wrapped lines; playbook bullets ≤ 8 (manual count
  acceptable).
- `plugin_version_bumped_in_same_change`: `plugin.json` version is `2.3.0` in the commit that
  introduces any of the above (see `release-wiring.md`).

### Manual

- Read each new bullet once as the auditor would, and confirm the eight contract fields are
  recoverable (trigger, set, invariant, absence, gate, cap, carve-out, cross-refs).
- Run the auditor against `tests/fixtures/c09-oracle-authority-unpinned` and
  `tests/fixtures/c11-governance-capture` and confirm candidates appear at the README-named
  locations with severity ≤ Medium when no on-chain evidence is supplied (sanity, not gate).

### Acceptance Criteria

- [ ] Every heading in §Class inventory exists verbatim in its file; the 6.8 rename is applied
      and the old heading is gone (REQ-COV-005, REQ-COV-040).
- [ ] C3: one to three 5.3a bullets covering candidates, write-boundary validation and
      same-domain caps (REQ-COV-006, 007, 008).
- [ ] C6: three 6.14 items; the immutability item states the High floor conditional on the
      feasibility gates and the Medium pattern-only cap (REQ-COV-015, 016, 017, REQ-COV-002).
- [ ] C7: caps-vs-depth bullet with the explicit depth-unknown `needs_review` path, recursive
      resupply and single-fill rejection bullets present in the lending playbook; ungated
      refresh bullet present in driver 7.2 (REQ-COV-018, 019, 020, 021).
- [ ] C8: ratio-feed composition, sanity band, coupled-parameter atomicity bullets present
      (REQ-COV-022, 023, 024).
- [ ] C9: new oracle-integrations section with the provider table; Pyth row requires feed-ID +
      originating-package + staleness + confidence and no authority pin; Switchboard row
      requires ID + queue + authority pin pending S-1; min-count/move-bound, round-trip, keeper
      plausibility bullets present; 7.2 explicit-load bullet with the full `${CLAUDE_PLUGIN_ROOT}`
      path added; `sui-native-pitfalls.md` companion-table load condition names oracle /
      third-party price-object consumption (REQ-COV-025, 026, 027, 028, REQ-REL-013).
- [ ] C11: trigger line binding outcomes to the verified-clean list plus five items (REQ-COV-009
      … 014).
- [ ] C12: three bullets; 1-of-1 item states the High floor and the reputation non-dismissal
      (REQ-COV-029, 030, 031).
- [ ] C19: Phase 1 step 10 with the "never produces a finding" sentence (REQ-COV-039).
- [ ] Four catalog rows added, Reentrancy row retained (REQ-COV-003).
- [ ] Every new bullet states or inherits the pattern-only ⇒ Medium cap, names what to report
      on absence, and names its enumeration set (REQ-COV-001, REQ-COV-002).
- [ ] No new bullet's subject is a protocol; incidents appear only parenthetically
      (REQ-COV-004).
- [ ] PR description carries the `CHK-ID | file | heading | first words` table (REQ-COV-040).
- [ ] Spike S-1 closed in the implement stage with the Switchboard field names recorded in the
      section's table, or the fallback wording adopted and noted.
- [ ] Both manifests still parse (`python3 -m json.tool`) — the repository's only lint.
