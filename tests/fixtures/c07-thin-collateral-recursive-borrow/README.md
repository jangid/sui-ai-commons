# Fixture: c07-thin-collateral-recursive-borrow

## Class

C7 — Oracle manipulation via thin collateral / recursive borrow / spot read.

## Mirrored incident

Tectonic (Cronos, 2026-08-30, ~$120.4M nominal, ~$111.2M rolled back): TONIC, with ~$1.34M of
on-chain liquidity, was listed at a 20% collateral factor with no supply or borrow cap; the
attacker looped borrow-then-re-supply 98 times in one transaction to hold two thirds of the
supply, moved the spot price ~300x with a ~$1.4M buy, and borrowed out all nine markets.
Secondary rows with the same mechanism: YieldBlox / Blend V2 (Stellar, 2026-02-22, ~$10.97M;
a VWAP oracle set by one SDEX trade at 100x, adapter returned the latest price with no
median or deviation check) and Makina Finance (ETH, 2026-01-20, ~$4.13M; permissionless
`updateTotalAum()` read flash-loan-skewed Curve spot balances). RS-001 catalog rows: Tectonic
2026-08-30, YieldBlox 2026-02-22, Makina 2026-01-20
(`docs/research/RS-001-exploit-coverage-refresh/findings.md`, class C7 row of the coverage-gap
table).

## Requirements

Acceptance evidence for REQ-COV-018, REQ-COV-019, REQ-COV-020 and REQ-COV-021 (the C7 check
contracts in `docs/spec/coverage-checks.md`), and for REQ-COV-041 and REQ-COV-042 (fixture
layout and README contract in `docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- CHK-C7-1 (REQ-COV-018) — collateral caps justified against liquidity depth.
- CHK-C7-2 (REQ-COV-019) — recursive borrow-and-resupply bounded.
- CHK-C7-3 (REQ-COV-020) — single-fill prices rejected.
- CHK-C7-4 (REQ-COV-021) — permissionless NAV/price refresh gated.

## Expected finding

- CHK-C7-1: `Market<T>` (`lending::list_market`) has no `supply_cap` or `borrow_cap` field;
  the only validated listing parameter is `collateral_factor_bps <= BPS`. Enumeration: one
  listed collateral asset (the market's `T`), zero caps. Outcome (a) "no cap" ⇒ candidate at
  `lending::list_market` / `Market.reserve`. Confidence `likely` (static reading of the absence); severity
  cap Medium pattern-only; High with depth evidence (depth is unknowable from source, so the
  report states that depth could not be assessed rather than skipping).
- CHK-C7-2: `lending::borrow` returns `Coin<T>` and `lending::supply` accepts `Coin<T>` of the
  same market; `Account<T>` tracks `supplied` and `borrowed` of the same asset with no
  same-asset check, no per-asset loop count and no per-tx exposure snapshot. PTB sequence:
  `supply(c) -> borrow(c * cf) -> supply(...) -> borrow(...)` repeated until the reserve is
  exhausted. Confidence `likely` (PTB sequence written, not executed); severity cap Medium
  pattern-only; High once the loop is replayed in a PTB trace against the deployed package.
- CHK-C7-3: the single oracle adapter is `PriceFeed.last_trade_price`, read by
  `lending::is_healthy` on the eligibility path; there is no TWAP/median, no second source and
  no per-update deviation bound. The seize-leg carve-out does not apply (this is the
  eligibility price). Confidence `likely` (static reading); severity cap Medium pattern-only, High once
  paired with the CHK-C7-2 loop (the manipulated price inflates every loop's capacity).
- CHK-C7-4: `lending::refresh_price` is `public`, takes no capability, and writes
  `PriceFeed.last_trade_price` with no TWAP or deviation gate (grep seed `refresh_price`
  hits). Confidence `likely` (static reading); severity cap Medium (pattern-only, inherits Phase 9).

## Expected noise

- `lending::borrow` and `lending::supply` price both legs with the same feed, so the health
  check is price-invariant for the single-asset case; a "price cancels out" remark is
  incidental — the class is the unbounded exposure and the manipulable eligibility price, which
  a two-asset market with the same body would exhibit directly.
- `AdminCap` is transferred to the publisher in `init`; a "single admin key" note is out of
  scope (listing is the only privileged action and it is capability-gated by design).
- No liquidation path exists in the fixture; "missing liquidation" is out of scope.

## Build

```
cd tests/fixtures/c07-thin-collateral-recursive-borrow
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
