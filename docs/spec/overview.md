---
status: Approved
last_updated: 2026-10-30
requires: []
---

# Overview — Exploit-Coverage Refresh for `sui-move-auditor`

## Context

RS-001 (`docs/research/RS-001-exploit-coverage-refresh/findings.md`) catalogued one year of
incidents (cutoff 2026-10-30) against the `sui-move-auditor` driver and its six playbooks and
found two uncovered root-cause classes (C3, C11), six partial classes (C6, C7, C8, C9, C12,
C20), a missing perpetuals/margin archetype, and one advisory item (C19). The approved
requirements (`docs/requirements/index.md`, 72 live IDs across SRC / COV / REL) say *what* must
hold afterwards. These specs say *where each thing lands and how a reviewer decides it is done*.
They do not contain the final check prose, grep seeds or playbook text — that is the implement
stage's output, constrained by the contracts here.

This file is the map. It carries no requirement of its own (`requires: []`) by design: every
requirement is owned by exactly one of the five feature specs below, so that the traceability
matrix has a single Spec cell per row. The skill's "no orphan specs" rule is satisfied by this
file's role as the index that the other five depend on.

## Design

### Architecture

The system under change is a prompt-driven agent: a Markdown **driver**
(`plugins/sui-ai/agents/sui-move-auditor.md`, Phases 1–11 plus 8B) that loads Markdown
**playbooks** from `plugins/sui-ai/agents/sui-move-auditor/` through a "COMPANION REFERENCES"
load-when table. There is no executable code in the plugin. Three consequences shape every
design decision in these specs:

1. **A "check" is instructing text at a heading.** Compliance is decided by reading or `grep`
   (REQ-COV-040), never by observing a run. Every check contract therefore names a file and an
   exact heading (existing, renamed, or new) and the properties the text under it must have.
2. **Load-on-demand must be preserved.** A check lands where the target that exhibits the class
   loads it (REQ-REL-013): generic Move mechanics in the driver, archetype mechanics in the
   matching playbook, platform/oracle/bridge mechanics in `sui-native-pitfalls.md`. A non-matching
   audit must read the same text as before, plus nothing.
3. **Fixtures are the only executable artifact.** `tests/fixtures/<class-slug>/` holds minimal
   vulnerable Sui Move packages that compile under Sui CLI 1.81.1 (REQ-COV-041). They live at
   repository level, outside `plugins/`, so they never affect the installed plugin or its version.

#### Pieces and how they fit

```
docs/exploit-sources.md                      ← SRC: durable source list + rerun procedure (no plugin bump)
docs/research/RS-00N-.../findings.md         ← SRC: each rerun is a new immutable spike
plugins/sui-ai/.claude-plugin/plugin.json    ← REL: version 2.2.0 → 2.3.0
plugins/sui-ai/agents/sui-move-auditor.md    ← COV: new/edited headings in Phases 1, 5.3a, 6.8, 6.14, 7.2 (incl. CHK-C7-4), 8B;
                                                REL: companion table row + all rows in full-path form (decision 9),
                                                sui-native-pitfalls load condition + oracle, description, Appendix C line
plugins/sui-ai/agents/sui-move-auditor/
  defi-perps-and-margin.md                   ← COV: NEW playbook (perps archetype, C17 perps side, C20, C3 sinks)
  defi-lending-and-liquidation.md            ← COV: C7 (CHK-C7-1..3), C8 bullets (margin content stays here)
  sui-native-pitfalls.md                     ← COV: C9 new section, C12 bullets
  verification-and-false-positives.md        ← COV: four new false-positive catalog rows (n/a classes)
CLAUDE.md                                    ← REL: playbook enumeration + tests/fixtures note
tests/fixtures/<class-slug>/                 ← COV: nine compiling vulnerable fixtures + READMEs
```

### Principles

- **Contracts, not prose.** Each check contract fixes: trigger (when the auditor runs it), the
  set it must enumerate, the invariant it verifies, the evidence gate it must pass before
  reporting, the severity cap, and the false-positive carve-outs. The implementer writes the
  bullet; the reviewer checks the bullet against the contract.
- **Driver style is a constraint.** New text must read like the existing text: terse bullets,
  bold lead-in, "load when" triggers, grep seeds in backticks, an explicit invariant, and an
  explicit "not a finding when…" carve-out where the zero-trust posture would over-report.
- **Severity is tied to confidence tiers.** `needs_review` (pattern-only) ⇒ max Medium
  (REQ-COV-002); `likely` ⇒ may reach High; `confirmed` ⇒ may reach Critical. The two "no lower
  than High" floors (REQ-COV-016, REQ-COV-029) apply only after the two-gate feasibility check
  passes, which already requires at least `likely`; the floors are therefore compatible with the
  tiers (resolves the index's open question on severity floors).
- **Operator decisions are binding.** Decisions 1–9 in `docs/handoff/kickoff.md` are cited by
  number; no spec reopens them. Decision 9 (strict companion path rule) is stated identically
  in `perps-playbook.md` and `release-wiring.md`: every companion-file mention in agent content
  uses `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md`, and the existing table and 8B
  rows are rewritten to that form in this cycle.
- **Nothing here changes the auditor's existing behaviour for non-matching targets.** Edits are
  additive bullets, one heading rename (6.8), one new playbook row, the path-form rewrite of the
  existing companion/8B rows (decision 9), and one load-condition addition
  (`sui-native-pitfalls.md` + oracle / third-party price-object consumption, so the C9 section
  is actually loaded).

### Spec map

| Spec | Scope | Requirements owned |
|---|---|---|
| `exploit-sources.md` | `docs/exploit-sources.md` file contract; rerun procedure; rerun spike contract | REQ-SRC-001 … REQ-SRC-018 (18) |
| `coverage-checks.md` | Per-class landing spot and check contract for C3, C6, C7, C8, C9, C11, C12, C19; cross-cutting check discipline; n/a-class catalog rows; content-level evidence rule | REQ-COV-001 … REQ-COV-031, REQ-COV-039, REQ-COV-040 (33) |
| `perps-playbook.md` | `defi-perps-and-margin.md` contract, load trigger, dual routing with the lending playbook, Phase 8B wiring, C17 perps side, C20, C3 sinks | REQ-COV-032 … REQ-COV-038 (7) |
| `fixtures.md` | `tests/fixtures/<class-slug>/` layout, slug list, `Move.toml` and README contracts, compile gate | REQ-COV-041, REQ-COV-042 (2) |
| `release-wiring.md` | Version 2.3.0, every enumeration site, manifests, placement, branch/PR, commit subject | REQ-REL-001 … 006, 008 … 013 (12) |

Total: 72 live requirements, each in exactly one spec. REQ-REL-007 is `[Deprecated]` and
has no spec.

#### Class → landing spot (summary; contracts in `coverage-checks.md` and `perps-playbook.md`)

| Class | File → heading (exact text the implementer must create or extend) |
|---|---|
| C3 signed-value reinterpretation | driver → `### 5.3a High-signal correctness greps (cheap, high severity)` (new bullet) and `defi-perps-and-margin.md` → `## Fees, funding and collateral deltas as signed-value sinks` |
| C6 cross-version desync | driver → `### 6.14 Package Upgrade Safety` (three new checkboxes) |
| C7 thin collateral / recursive borrow / spot read | `defi-lending-and-liquidation.md` → `## Market creation & configuration validation` (sub-block **Collateral listing quality**) and `## Oracle staleness & price representability`; CHK-C7-4 (permissionless refresh) → driver `### 7.2 Oracle & Price Manipulation` |
| C8 oracle misconfiguration | `defi-lending-and-liquidation.md` → `## Oracle staleness & price representability` |
| C9 oracle authority | `sui-native-pitfalls.md` → `## Oracle integrations (Pyth / Switchboard / custom feeds)` (new section); driver → `### 7.2 Oracle & Price Manipulation` (explicit-load bullet with the full path); companion table → `sui-native-pitfalls.md` load condition + "oracle / third-party price-object consumption" |
| C11 governance capture | driver → `### 6.8 Governance, Voting & Weight Safety` (renamed from "6.8 Weight & Governance Safety") |
| C12 bridge verification | `sui-native-pitfalls.md` → `## Cross-chain / bridge / ZK` (three new bullets) |
| C19 platform / VM (advisory) | driver → `## PHASE 1 — CONTEXT GATHERING` (new numbered step 10) |
| C17 perps side, C20, perps archetype | `defi-perps-and-margin.md` (new file; headings fixed in `perps-playbook.md`) |
| C22, C23, C25, token-approval abuse, EVM proxy (n/a) | `verification-and-false-positives.md` → `## Move-specific false-positive catalog ("looks vulnerable, is safe")` (four new rows) |

## Verification

This file verifies the *spec set*, not the product; per-feature verification lives in each
feature spec.

### Automated

- `every_live_requirement_owned_once`: parse `requires:` from every `docs/spec/*.md`; the union
  equals the set of non-deprecated rows in `docs/requirements/traceability.md` (72), and no ID
  appears in two specs. (Run 2026-10-30: 72/72, 0 duplicates.)
- `traceability_spec_column_filled`: every live row's Spec cell names an existing file in
  `docs/spec/`; the `[Deprecated]` row stays empty.
- `all_specs_have_required_sections`: each feature spec contains `## Context`, `## Design`,
  `## Verification`, `### Automated`, `### Manual`, `### Acceptance Criteria`.
- `landing_headings_consistent_across_specs`: every heading string in the class → landing spot
  table above appears identically in `coverage-checks.md` §Class inventory or
  `perps-playbook.md` §Section skeleton.
- `fixture_slugs_consistent`: the nine slugs in `fixtures.md` equal the slug column of
  `coverage-checks.md` §Class inventory plus the two perps slugs named in `perps-playbook.md`.
- `high_uncertainty_sections_have_spike_and_fallback`: each `[high-uncertainty]` marker is
  followed by a bounded spike (tool-call budget) and a fallback design (S-1, S-2).

### Manual

- Read the six files in the order overview → exploit-sources → coverage-checks →
  perps-playbook → fixtures → release-wiring and confirm no spec needs another to be
  understood beyond the cited headings and IDs.

### Acceptance Criteria

- [ ] The two recorded passes below (cross-spec consistency, coverage) report no open findings.
- [ ] Status of all six specs flipped to Approved by the orchestrator at the gate (this stage
      writes Draft only).
- [ ] The plan stage can derive spike tasks S-1 and S-2 from the `[high-uncertainty]` sections
      without further clarification.

## Cross-spec consistency pass (recorded result)

Run per the specs skill Step 4b on 2026-10-30 over the six files in `docs/spec/`.

- **Type extraction.** The specs contain no code blocks defining Python/TypeScript/Rust types.
  The only Move `struct` definitions appear in `fixtures.md` (illustrative fixture shapes:
  `IntegratorInfo`, `Pool`, `Proposal`, `Aggregator`-consumer `Config`) and are marked
  "illustrative, not normative". Result: **no extractable normative type definitions in
  overview.md, exploit-sources.md, coverage-checks.md, perps-playbook.md, release-wiring.md**;
  `fixtures.md` defines illustrative shapes only, referenced by no other spec.
- **Cross-spec name references validated.** `coverage-checks.md` references the heading
  `## Fees, funding and collateral deltas as signed-value sinks` defined in `perps-playbook.md`
  (present); `perps-playbook.md` references the C3 contract (CHK-C3-1..3) in
  `coverage-checks.md` (present); `fixtures.md` references check IDs CHK-* and PB-* from both
  (all present); `release-wiring.md` references the companion-table row text and the Phase 8B
  row text fixed in `perps-playbook.md` (identical strings; checked by eye). The class-slug
  list in `fixtures.md` matches the class list in `coverage-checks.md` §Class inventory
  (nine slugs, C19 exempt).
- **Re-run 2026-10-30 after review iteration 1 (fix pass).** Checked: (i) `fixtures.md` slug
  table now lists CHK-C11-0..5 for `c11-governance-capture`, matching `coverage-checks.md`
  §Class inventory — the earlier "mapping complete" statement was wrong for CHK-C11-0 and is
  corrected (M7); 31 check IDs each map to exactly one slug, CHK-C19-1 exempt, `CAT-*` are not
  checks. (ii) The CHK-C7-4 landing (driver 7.2) is stated identically in `coverage-checks.md`
  §Class inventory/§C7, `release-wiring.md` §Change-set inventory/§Placement and this file's
  table (M8). (iii) The `sui-native-pitfalls.md` load-condition amendment and the 7.2
  explicit-load bullet appear in `coverage-checks.md`, `release-wiring.md` and this file (M1).
  (iv) The companion path rule text is the same in `perps-playbook.md` and `release-wiring.md`,
  and the fixed companion-table/8B row strings in `perps-playbook.md` use the full-path form
  that `release-wiring.md`'s checks require (M4). (v) `exploit-sources.md`'s spike contract now
  sits inside procedure step 10 and its grep list covers it (M6); #7 is `never attempted` in
  both the Initial content paragraph and the Retry list (M5). (vi) The automated-check shell in
  `fixtures.md` and `coverage-checks.md` was re-read against the stated landing headings (M2,
  M3). No type definitions were added; the type-extraction result is unchanged.
- **Findings:** none open. One naming decision was made deliberately: `coverage-checks.md`
  uses check IDs `CHK-<class>-<n>` and `perps-playbook.md` uses `PB-<n>`; fixtures and
  release-wiring cite those IDs rather than restating check text.

## Coverage check (recorded result)

Per the specs skill Step 5, against `docs/requirements/traceability.md` after the Spec column
was filled:

```
REQ-SRC-001..018  → exploit-sources.md   (18 covered)
REQ-COV-001..031  → coverage-checks.md   (31 covered)
REQ-COV-032..038  → perps-playbook.md    (7 covered)
REQ-COV-039, 040  → coverage-checks.md   (2 covered)
REQ-COV-041, 042  → fixtures.md          (2 covered)
REQ-REL-001..006, 008..013 → release-wiring.md (12 covered)
REQ-REL-007       → [Deprecated], no spec (expected)
[Uncovered]: none
[Orphan specs]: none (overview.md is the index by design; see Context)
[High-uncertainty]:
  coverage-checks.md §CHK-C9-1 — Switchboard Aggregator authority model (bounded spike S-1)
  fixtures.md §Move.toml contract — implicit vs explicit framework dependency under Sui 1.81.1 (bounded spike S-2)
```

Re-run 2026-10-30 after review iteration 1: ownership unchanged (72/72, 0 duplicates); no
requirement moved between specs; `docs/requirements/traceability.md` was not touched by the fix
pass. REQ-COV-021 stays owned by `coverage-checks.md` (CHK-C7-4 relocated within that spec to
driver 7.2); REQ-REL-013 stays owned by `release-wiring.md`.

## Open Questions

- **overview.md carries `requires: []`.** The dispatch's "each requirement in exactly one
  spec" rule and the skill's "no orphan specs" rule were reconciled by making this file the
  index rather than an owner. If the gate prefers every spec to own at least one ID, the
  cheapest change is to move REQ-COV-005 (every gap class citable) here — the class → landing
  spot table above is literally that map — and drop it from `coverage-checks.md`.
- **Heading rename of driver §6.8.** RS-001 suggests renaming "6.8 Weight & Governance Safety"
  to "6.8 Governance, Voting & Weight Safety". Nothing in the repository references the old
  heading text (grep on 2026-10-30: zero hits outside RS-001). The rename is adopted; if the
  operator prefers heading stability, the five governance checks can land under the old heading
  with no other change to the contract.
- **CLAUDE.md "no test suite" sentence.** Adding `tests/fixtures/` makes the sentence "There is
  no application code, build system, or test suite" partly stale. `release-wiring.md` requires a
  one-line amendment; it is a documentation edit, not a plugin change, so it does not affect the
  version bump.
