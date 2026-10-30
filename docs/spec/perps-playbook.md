---
status: Approved
last_updated: 2026-10-30
requires: [REQ-COV-032, REQ-COV-033, REQ-COV-034, REQ-COV-035, REQ-COV-036, REQ-COV-037, REQ-COV-038]
---

# Perpetuals and Margin Playbook

## Context

Seven of this year's incidents (Aftermath, Ostium, Mars Perps, Rocket Perp, Papertrade,
SecuredFi, Perpetual Protocol v2) are perpetual-futures or margin protocols, and the driver's
companion table has no playbook for them. Operator decision 2 fixes the answer: a **new**
companion playbook `plugins/sui-ai/agents/sui-move-auditor/defi-perps-and-margin.md`,
referenced from the driver with the `${CLAUDE_PLUGIN_ROOT}` prefix. This spec defines that
file's contract, its load trigger, the dual routing of margin targets (REQ-COV-033), and the five
check blocks it must carry (REQ-COV-034 … 038). It fulfils REQ-COV-032 … 038.

The playbook is written in the same register as the four existing DeFi playbooks (a "Load when"
opener, `##` mechanism sections, bold-lead-in bullets, a closing known-good-patterns section) so
the driver's Phase 8B can treat it identically.

## Design

### File and load trigger (REQ-COV-032, REQ-COV-033)

- Path (fixed): `plugins/sui-ai/agents/sui-move-auditor/defi-perps-and-margin.md`.
- Opening line (fixed intent): "Load when the target exposes leveraged positions, funding rates,
  margin accounts, or position liquidation (perpetual futures, margin trading, builder/integrator
  fee codes). **A margin target also keeps
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md` loaded** — this
  playbook adds perps mechanics; it does not replace the lending playbook's margin-account
  content (self-match, post-trade health)."
- Companion-table row in the driver (fixed text; `release-wiring.md` repeats it verbatim):

  `| \`${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md\` | Leveraged positions, funding rates, margin accounts, position liquidation, integrator/builder fee codes — **load together with** \`${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md\` for any margin target |`

  Inserted after the lending row. The lending row's load-when text gains the suffix "— margin
  targets also load `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md`"
  so the dual load is stated on both rows (REQ-COV-033 "the companion-references table must
  state the same dual load").
- **Companion path rule (operator decision 9, strict; stated identically in
  `release-wiring.md` §Companion wiring):** every mention of a companion playbook file in agent
  content — the companion table's first-column cells, the Phase 8B list, and every in-text
  "see X.md" mention in the driver or a playbook — uses the full
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md` form. The existing six table rows
  and four 8B rows are rewritten to that form in this cycle (edit owned by `release-wiring.md`).
  Headings or prose that name a file as a concept are acceptable only if the same bullet also
  gives the full path once. Consequently the perps playbook's own cross-references (PB-1, PB-3
  below) are written with the full path in the file, even though this spec abbreviates them to
  the bare filename for readability.
- Phase 8B row (fixed text): the existing **Lending / margin** bullet becomes
  **Lending / margin** → `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md`
  **and, for margin or leveraged targets,**
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md` (…existing
  parenthetical…; perps: funding settlement
  order, funding-rate bounds, self-trade on thin books, risk-parameter transitions, signed-value
  fee/funding/collateral sinks). Decision: extend the existing row rather than add a fifth
  archetype row, because REQ-COV-033 and REQ-REL-008 both name the "Lending / margin" row as
  the one that must list both files; a perps-only target still matches it via "leveraged".
- No margin content moves out of the lending playbook (fixed): the lending playbook's
  `## Self-liquidation & self-match` section is untouched; the perps playbook cross-references it
  by heading instead of duplicating.

### Section skeleton (fixed headings)

```
# Playbook — Perpetuals, Funding & Margin
<Load when … (dual-load sentence)>
## Funding settlement ordering                         ← PB-1 (REQ-COV-034)
## Funding-rate updates: permissioned or bounded       ← PB-2 (REQ-COV-035)
## Self-trade and mark-price manipulation on thin books ← PB-3 (REQ-COV-036)
## Risk-parameter changes and open positions           ← PB-4 (REQ-COV-037)
## Fees, funding and collateral deltas as signed-value sinks ← PB-5 (REQ-COV-038)
## Known-good patterns — DO NOT report these as bugs
```

A one-line preamble under the title states the severity discipline for the file: "Pattern-only
candidates are `needs_review` ⇒ max Medium; High needs the traced path and the math-bounds gate
(`verification-and-false-positives.md`)." Rationale: mirrors the cap statement the lending
playbook makes via its known-good section and satisfies REQ-COV-002 once for the whole file.

### Check contracts (schema as in `coverage-checks.md`)

- **PB-1 (REQ-COV-034) — funding settled before any position or collateral change.** Trigger:
  playbook loaded. Enumerate: every function that changes position size, margin, or collateral
  on an account (open/increase/decrease/close, add/remove collateral, liquidate, transfer
  position). Invariant: accrued funding for the affected account is settled (global funding
  index advanced and the account's pending funding applied) as the first state-mutating
  operation. Absence: a mutating path with no settle call = candidate; the fast tell is the same
  as the lending playbook's accrual rule — a mutator with no `Clock`/index parameter cannot
  settle. Cross-reference `defi-lending-and-liquidation.md` → `## Interest & accrual ordering`
  and `defi-staking-and-rewards.md` → `## Checkpoint & accumulator ordering (the core bugs)`
  (same mechanism, different accumulator). Carve-out: a continuous funding accumulator settled
  lazily on read *and* re-read after every mutation (trace both reads).
- **PB-2 (REQ-COV-035) — funding-rate updates permissioned or bounded.** Enumerate: every
  function that writes the funding rate or the funding index (grep seeds
  `funding_rate|funding_index|cumulative_funding|update_funding|set_funding`). Invariant: each
  writer is capability-gated, or the per-update and per-interval change is bounded by constants
  with floors/ceilings the setter enforces. Report a **funding-manipulation window**: a rate that
  an unprivileged caller can move and harvest within one interval (state the interval and the
  harvest path). Carve-out: a permissionless `poke` that only advances time at a rate derived from
  a bounded premium index (show the bound).
- **PB-3 (REQ-COV-036) — self-trade on thin books moves the settlement price.** Enumerate: every
  matching / fill path and every read of mark or index price used for settlement, liquidation,
  or PnL. Invariant: a self-match guard compares **owner addresses, not account IDs** (extends
  the lending playbook's self-match bullet — cite it) and the mark price used for settlement is
  smoothed or bounded (EMA / TWAP / max deviation from index) so a same-block self-trade on a
  thin book or thin virtual liquidity cannot move it. Absence of either = candidate (name which).
  Cross-reference `defi-amm-and-slippage.md` → `## Order books & matching loops` for the
  book-walk mechanics. Carve-out: an oracle-only mark price never derived from fills.
- **PB-4 (REQ-COV-037) — risk-parameter changes re-check open positions.** Enumerate: every
  setter of maintenance margin, leverage cap, collateral weight / haircut, or liquidation
  threshold. Invariant: the change is applied with a re-check of existing positions or through a
  transition window (grace period / stepwise change), so that no open position becomes
  unexaminable (abort in the health path) or instantly liquidatable without notice. Report a
  setter that leaves open positions either state. Cross-reference the lending playbook's
  **LTV strictly below the liquidation threshold, with a gap** and the driver's
  **Admin-origin latent user DoS**. Carve-out: parameters that can only tighten within a bounded
  step and only after a timelock whose length the bullet states.
- **PB-5 (REQ-COV-038) — fee, funding and collateral deltas as signed-value sinks.** Fixed
  heading `## Fees, funding and collateral deltas as signed-value sinks` (cited by
  `coverage-checks.md` CHK-C3). Content: names the perps value sinks — taker/maker fee,
  integrator/builder fee codes, funding payments, realised PnL, collateral deltas
  (`add_to_collateral`-shaped functions) — and instructs the auditor to run the driver's
  **Raw-bits stored, signed-read** check (5.3a) with these as the sink set, tracing each fee or
  rate field from its constructor to the sink and checking write-boundary validation and
  same-domain caps there. Decision: the playbook does not restate the C3 contract; it supplies
  the sink list and a one-line pointer. Rationale: a single source of truth for the C3 mechanism
  (driver) with the archetype supplying the sinks keeps the two in sync when either changes.

### Known-good patterns section (false-positive suppressors)

Required entries (fixed intent): (a) funding settled lazily at read time *is* correct when every
mutator reads first — not a finding; (b) a permissioned funding-rate setter held by a
declared-trusted keeper is not itself a finding (trust model) — report blast radius and missing
bounds instead; (c) mark ≠ index by design: a bounded premium between them is the funding
mechanism, not manipulation; (d) sanity gate before filing a perps liquidation finding: would the
fix make liquidation unprofitable or impossible at high utilisation (the lending playbook's
rule)? Rationale: the lending playbook's experience is that zero-trust over-reports here in ways
that make protocols less safe; the same guardrail is needed for perps.

### Interaction with other specs

- `coverage-checks.md` — CHK-C3 depends on PB-5's heading; `defi-lending-and-liquidation.md`
  edits for C7/C8 are specified there, not here.
- `fixtures.md` — slugs `perps-funding-settlement-ordering` (PB-1), `c20-perps-market-manipulation`
  (PB-2..4), `c03-signed-value-reinterpretation` (PB-5 with CHK-C3).
- `release-wiring.md` — companion-table row, Phase 8B row, description and Appendix C updates,
  version 2.3.0.

## Verification

### Automated

(`D=plugins/sui-ai/agents/sui-move-auditor.md`, `P=plugins/sui-ai/agents/sui-move-auditor`,
`F=$P/defi-perps-and-margin.md`)

- `playbook_file_exists_in_companion_dir`: `test -f $F`.
- `load_when_opener_states_dual_load`: first 6 lines of `$F` contain "Load when" and
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md`.
- `six_fixed_headings_present_in_order`: `grep -n '^## '` on `$F` yields the six headings of the
  skeleton in that order, including the exact string
  `## Fees, funding and collateral deltas as signed-value sinks`.
- `preamble_states_cap`: `$F` contains "max Medium" within its first 10 lines.
- `pb1_settle_first`: section 1 contains "before" (or "first") and `Clock`.
- `pb2_window_named`: section 2 contains "window" and ("permission" or "bounded").
- `pb3_owner_not_account`: section 3 contains "owner address" and ("mark" and "smooth" or
  "deviation").
- `pb4_transition`: section 4 contains ("re-check" or "recheck") and ("transition" or "grace").
- `pb5_points_to_driver`: section 5 contains "5.3a" (or "Raw-bits") and lists at least "fee",
  "funding", "collateral".
- `known_good_section_present`: `$F` contains a heading starting `## Known-good patterns`.
- `companion_table_row_present`: `$D` contains a table row whose first cell is
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md` and which contains
  "load together with" (or "also load"); the lending row mentions
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md`.
- `phase_8b_row_names_both`: between `## PHASE 8B` and `## PHASE 9` in `$D`, the "Lending /
  margin" line contains both `defi-lending-and-liquidation.md` and `defi-perps-and-margin.md`.
- `no_bare_companion_mention_perps`: `grep -nE '(^|[^/])defi-perps-and-margin\.md' $D $P/*.md | grep -v CLAUDE_PLUGIN_ROOT`
  returns zero lines, and the same grep over `$F` for the other six companion filenames returns
  zero lines — every mention of the new file, and every cross-reference from `$F` to another
  playbook, carries the full `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/` path on the same
  line (operator decision 9; the whole-corpus check is `release-wiring.md`
  `no_bare_companion_mention`).
- `lending_margin_content_untouched`: `git diff <base> -- plugins/sui-ai/agents/sui-move-auditor/defi-lending-and-liquidation.md`
  shows no deletions under `## Self-liquidation & self-match`.

### Manual

- Run the auditor against `tests/fixtures/c20-perps-market-manipulation` and confirm that both
  the lending playbook and the perps playbook are reported as loaded (the agent lists companions
  it read) and that PB-2..4 candidates appear at the README-named functions (sanity, not gate).

### Acceptance Criteria

- [ ] `defi-perps-and-margin.md` exists at the fixed path with the opener, preamble, six
      headings and known-good section (REQ-COV-032).
- [ ] Driver companion table has the perps row with the dual-load statement and the lending
      row's suffix; Phase 8B "Lending / margin" row names both files; lending playbook margin
      content unchanged (REQ-COV-033).
- [ ] PB-1 … PB-5 contracts each recoverable from the text: trigger, set, invariant, absence,
      cap, carve-out (REQ-COV-034, 035, 036, 037, 038; REQ-COV-001, 002 via preamble).
- [ ] PB-5 names the sink list and points to the driver's 5.3a bullet rather than restating it
      (REQ-COV-038).
- [ ] Every mention of `defi-perps-and-margin.md` in agent content — companion table, Phase 8B
      list, in-text mentions — and every cross-reference inside the playbook uses the full
      `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md` form; no bare filename remains
      (operator decision 9; REQ-REL-002 via `release-wiring.md`).
- [ ] `plugin.json` version is 2.3.0 in the same change (REQ-REL-001 via `release-wiring.md`).
- [ ] Both manifests parse with `python3 -m json.tool`.
