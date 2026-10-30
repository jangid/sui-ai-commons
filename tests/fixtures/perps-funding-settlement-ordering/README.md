# Fixture: perps-funding-settlement-ordering

## Class

Perps archetype (C17 perps side) — funding settled after, not before, a position or collateral
change.

## Mirrored incident

Perpetual Protocol v2 "Curie" (Optimism, 2026-07-16): an unguarded `OrderBook` funding-growth
update let cached funding be poisoned and the Vault drained because position paths consumed
funding state that had not been settled first. BiFi (2026-10-17) is the lending-side twin: an
idle market froze the per-block exchange rate and booked the whole inactive gap on the first
action. RS-001 catalog rows: Perpetual Protocol v2 2026-07-16, BiFi 2026-10-17
(`docs/research/RS-001-exploit-coverage-refresh/findings.md`, class C17 row of the coverage-gap
table, perps side folded into the C20/perps-archetype note).

## Requirements

Acceptance evidence for REQ-COV-034 (the PB-1 check contract in `docs/spec/perps-playbook.md`),
and for REQ-COV-041 and REQ-COV-042 (fixture layout and README contract in
`docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- PB-1 (REQ-COV-034) — funding settled before any position or collateral change.

## Expected finding

- PB-1: `positions::increase_position` writes `Position.size = size + delta` and only then calls
  `positions::settle_funding`, so the funding accrued since the last snapshot is charged on the
  new size rather than the size that accrued it; `positions::add_collateral` writes
  `Position.margin = margin + amount` before the same call. Settlement must be the first
  state-mutating operation on the affected account. The fast tell does not apply (the mutators
  do receive `&Market`, i.e. the index) — the ordering itself is the candidate. Cross-reference
  `defi-lending-and-liquidation.md` → `## Interest & accrual ordering` and
  `defi-staking-and-rewards.md` → `## Checkpoint & accumulator ordering (the core bugs)`.
  Confidence `likely` (both paths are three lines in one module; static reading); severity cap
  Medium pattern-only; High once a mis-charged funding settlement is shown on-chain or in a PTB
  trace against the deployed package.

## Expected noise

- `positions::update_funding` is capability-gated and bounded by `MAX_RATE_PER_MS`; it is the
  known-good pattern (b) of the perps playbook and must not be reported as a funding-rate
  permission or bound finding (that check is owned by `c20-perps-market-manipulation`).
- `positions::remove_collateral` settles first and is the known-good contrast; it must not be
  reported.
- `positions::settle_funding` clips the owed amount at the current margin instead of recording
  bad debt; a "no bad-debt accounting" note is an expected incidental, outside PB-1.

## Build

```
cd tests/fixtures/perps-funding-settlement-ordering
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
