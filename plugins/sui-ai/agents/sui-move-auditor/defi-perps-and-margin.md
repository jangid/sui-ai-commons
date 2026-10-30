# Playbook — Perpetuals, Funding & Margin

Load when the target exposes leveraged positions, funding rates, margin accounts, or position
liquidation (perpetual futures, margin trading, builder/integrator fee codes). **A margin target
also keeps `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md`
loaded** — this playbook adds perps mechanics; it does not replace the lending playbook's
margin-account content (self-match, post-trade health).

Severity discipline for this file: pattern-only candidates are `needs_review` ⇒ max Medium; High
needs the traced path and the math-bounds gate
(`${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/verification-and-false-positives.md`).
Read the known-good section at the end **before reporting**.

## Funding settlement ordering

- **Settle funding before any position or collateral change.** Enumerate every function that
  changes position size, margin or collateral on an account — open/increase/decrease/close,
  add/remove collateral, liquidate, transfer position (grep `fun open_|fun close_|fun increase_|
  fun decrease_|fun add_collateral|fun remove_collateral|fun liquidate|fun transfer_position`).
  In each, accrued funding for the affected account must be settled first — global funding index
  advanced, then the account's pending funding applied — as the first state-mutating operation.
  A mutating path with no settle call is a candidate; name the function (Perpetual Protocol v2).
- **Fast tell: a mutator with no `Clock` or index parameter physically cannot settle.** Same rule
  as the lending playbook's accrual bullet — grep each mutator's signature for `&Clock` or the
  funding-index struct; a position mutator taking neither is reported as unsettled unless the
  settle happens in a shared helper it calls (trace the helper, do not assume). Cap: pattern-only
  ⇒ Medium; High once the unsettled path and the harvest (who gains from stale funding) are traced.
- **Same mechanism, different accumulator.** Cross-reference
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md` →
  `## Interest & accrual ordering` and
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-staking-and-rewards.md` →
  `## Checkpoint & accumulator ordering (the core bugs)` — the funding index is a per-position
  reward-debt accumulator and inherits every ordering bug listed there, including the
  abort-before-checkpoint deadlock and the parameter-change-without-settle retroactivity.
- **Not a finding when** the funding accumulator is continuous and settled lazily on read *and*
  every mutator re-reads it after mutating — trace both reads before dismissing (a read-before
  without a read-after leaves the post-mutation size accruing at the pre-mutation rate).

## Funding-rate updates: permissioned or bounded

- **Every funding-rate or funding-index writer is capability-gated or bounded.** Enumerate every
  function that writes the rate or the index (grep seeds
  `funding_rate|funding_index|cumulative_funding|update_funding|set_funding`). Each writer must
  either require a capability whose holder is enumerated in Phase 2, or bound the per-update and
  per-interval change with constants — floors and ceilings the setter itself enforces
  (`assert!(rate <= MAX_FUNDING_RATE)`, clamp on the premium). A writer with neither permission
  nor bound is a candidate; name it and the field it moves.
- **Report a funding-manipulation window.** When an unprivileged caller can move the rate and
  harvest within one funding interval — push the premium on a thin book, call the update, collect
  funding, unwind — state the interval length, the input the caller controls, and the harvest
  path (Mars Perps). Cap: `needs_review` ⇒ Medium until the harvest leg is written as a
  concrete PTB sequence; `likely` ⇒ High with the sequence and the bound (or its absence) cited.
- **Funding index derived from a manipulable mark.** If the rate is computed from mark − index
  and the mark is fill-derived, the bound here is only as good as the mark smoothing — apply the
  self-trade section below to the same read before accepting a "bounded" rate.
- **Not a finding when** a permissionless `poke`/`update_funding` only advances time at a rate
  derived from a bounded premium index — show the bound (constant and where it is asserted) in
  the verified-clean entry rather than reporting the permissionless call itself.

## Self-trade and mark-price manipulation on thin books

- **Self-match guard compares owner addresses, not account IDs.** Enumerate every matching /
  fill path (grep `fun match|fun fill|fun execute_order|fun take|fun settle_trade`). One owner
  holding two margin accounts must be unable to trade against themself to print a settlement
  price; a guard keyed on `account_id`/`position_id` alone is a candidate. This extends the
  lending bullet **Self-match protection compares owner addresses, not account IDs** in
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md` →
  `## Self-liquidation & self-match` — cite it rather than restating it (SecuredFi).
- **Mark price used for settlement, liquidation or PnL is smoothed or bounded.** Enumerate every
  read of mark or index price on those paths (grep `mark_price|index_price|oracle_price|twap|
  ema`). The mark must be an EMA/TWAP of fills, or clamped to a max deviation from the index,
  so a same-block self-trade on a thin book or thin virtual liquidity cannot move it. Absence of
  either guard (self-match or smoothing) is a candidate — name which. Cap: pattern-only ⇒
  Medium; High needs the book depth and the price move the attacker's size produces.
- **Book-walk mechanics.** For the matching-loop and depth questions (gas-bounded walks, partial
  fills, worst-fill accounting) see
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-amm-and-slippage.md` →
  `## Order books & matching loops`; the perps-specific question is only whether the resulting
  price feeds settlement.
- **Not a finding when** the mark is oracle-only and never derived from fills — then the oracle
  checks apply (`## Oracle integrations` in
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/sui-native-pitfalls.md`) and self-trade can at
  most pay fees to the protocol.

## Risk-parameter changes and open positions

- **Every risk-parameter setter re-checks open positions or uses a transition window.**
  Enumerate every setter of maintenance margin, leverage cap, collateral weight / haircut, or
  liquidation threshold (grep `fun set_maintenance|fun set_max_leverage|fun set_.*weight|
  fun set_.*haircut|fun set_liq`). The change must be applied with a re-check of existing
  positions, or through a transition — grace period, stepwise change — so that no open position
  becomes unexaminable (abort in the health path) or instantly liquidatable without notice.
  Report a setter that leaves open positions in either state; name the parameter and the state.
- **Both failure modes are findings.** A tightening that makes healthy positions instantly
  liquidatable is a blast-radius finding even when admin-only (trust-model qualifier: report
  the missing transition, not the admin's intent). A change that makes the health path abort —
  a zero divisor, an inverted min/max, a weight the stored position type cannot represent —
  is the driver's **Admin-origin latent user DoS** in perps clothing. Cap: pattern-only ⇒
  Medium; `likely` with a concrete position that the new parameter strands or liquidates.
- **Cross-reference the lending algebra.** The lending bullet **LTV strictly below the
  liquidation threshold, with a gap** in
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md` applies to
  initial vs. maintenance margin here: a setter that can close the gap to zero parks every
  position at the liquidation boundary.
- **Not a finding when** parameters can only tighten within a bounded step and only after a
  timelock — state the step bound and the timelock length in the verified-clean entry; an
  unbounded step or a zero-length timelock does not qualify.

## Fees, funding and collateral deltas as signed-value sinks

- **Perps value sinks for the driver's signed-value check.** The sink set for this archetype is:
  taker/maker fee, integrator/builder fee codes, funding payments, realised PnL, and collateral
  deltas (`add_to_collateral`-shaped functions, grep `add_to_collateral|apply_funding|
  realize_pnl|settle_pnl|charge_fee|integrator|builder`). Run the driver's 5.3a bullet
  **Raw-bits stored, signed-read (domain reinterpretation)** with these as the sink set, tracing
  each fee or rate field from its constructor to the sink and checking write-boundary validation
  and same-domain caps there (Aftermath Perps). This playbook supplies the sinks only; the
  contract, evidence gate and cap live in that driver bullet and are not restated here.

## Known-good patterns — DO NOT report these as bugs

- **Funding settled lazily at read time.** Correct when every mutator reads (settles) first — the
  lazy accumulator is the standard design, not a missing settle; the finding is only a mutator
  that skips the read (trace it under the first section).
- **Permissioned funding-rate setter held by a declared-trusted keeper.** Not itself a finding
  (trust model). Report the blast radius — what one keeper update can move — and any missing
  per-update bound instead; do not report "centralised funding".
- **Mark ≠ index by design.** A bounded premium between mark and index *is* the funding
  mechanism; report only an unbounded premium or a fill-derived mark with no smoothing/deviation
  clamp, never the existence of a premium.
- **Liquidation-profitability sanity gate.** Before filing any perps liquidation finding, ask the
  lending playbook's question: would the fix make liquidation unprofitable or impossible at high
  utilisation? If so, the "fix" causes bad debt — reframe or drop
  (`${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md`, known-good
  section).
