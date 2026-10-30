# Fixture: c08-oracle-ratio-feed-misconfig

## Class

C8 — Oracle misconfiguration (ratio-as-USD, desynced cap parameters, missing conversion).

## Mirrored incident

Moonwell cbETH market (Base / Optimism, 2026-02-15, ~$1.78M): a newly configured cbETH feed
returned the cbETH/ETH *ratio* (~1.12) and was consumed as a USD price without ever being
multiplied by ETH/USD, so liquidation bots seized cbETH collateral at $1.12; the fix sat behind
a 5-day timelock. Secondary rows with the coupled-parameter mechanism: Aave V3 wstETH CAPO
(ETH, 2026-03-10, ~$27.78M of healthy positions liquidated; `snapshotRatio` was updated but
rate-limited while `snapshotTimestamp` stayed seven days old, so the extrapolated cap sat
2.85% below market) and Silo V2 (Arbitrum, 2026-04-03, ~$0.36M, oracle misconfiguration).
RS-001 catalog rows: Moonwell cbETH 2026-02-15, Aave V3 CAPO 2026-03-10, Silo V2 2026-04-03
(`docs/research/RS-001-exploit-coverage-refresh/findings.md`, class C8 row of the coverage-gap
table).

## Requirements

Acceptance evidence for REQ-COV-022, REQ-COV-023 and REQ-COV-024 (the C8 check contracts in
`docs/spec/coverage-checks.md`), and for REQ-COV-041 and REQ-COV-042 (fixture layout and
README contract in `docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- CHK-C8-1 (REQ-COV-022) — ratio feeds composed with a base feed.
- CHK-C8-2 (REQ-COV-023) — sanity band on feed changes.
- CHK-C8-3 (REQ-COV-024) — coupled cap parameters move together.

## Expected finding

- CHK-C8-1: the one consumed feed, `OracleConfig.collateral_feed`, carries an `is_ratio`
  classification that `oracle_config::collateral_price_usd` never reads; the capped feed value
  flows unchanged into `oracle_config::is_liquidatable` as a USD price, so a ratio feed is
  consumed as USD and no base/USD multiplication exists anywhere in the module. Confidence
  `likely` (health-path read traced from `collateral_price_usd` to `is_liquidatable`);
  severity cap Medium pattern-only, High with the Moonwell numbers (a 1.12 ratio prices the
  collateral at $1.12 and every position becomes liquidatable).
- CHK-C8-2: `oracle_config::set_feed` replaces `collateral_feed` in one step; the new `value`
  is only checked for `> 0`, not against the previous value or a secondary reference, and
  there is no time-lock. Admin-only trigger does not dismiss it (trust qualification applies).
  Confidence `likely` (static reading); severity cap Medium pattern-only; High once a one-step
  `set_feed` to an arbitrary price is shown on-chain or in a PTB trace (blast-radius finding).
- CHK-C8-3: the growth cap's coupled parameters `snapshot_ratio`, `snapshot_timestamp_ms` and
  `max_yearly_growth_bps` have three separate setters (`oracle_config::set_snapshot_ratio`,
  `oracle_config::set_snapshot_timestamp`, `oracle_config::set_max_yearly_growth`); only
  `oracle_config::create` writes ratio and timestamp together. Calling `set_snapshot_ratio`
  alone reproduces the Aave CAPO desync in `oracle_config::capped_value`. The
  struct-replacing-setter carve-out does not apply (no setter replaces the whole snapshot).
  Confidence `likely` (static reading); severity cap Medium pattern-only; High once a lone
  `set_snapshot_ratio` call is shown desynchronising `capped_value` on-chain or in a PTB trace.

## Expected noise

- `Feed.is_ratio` is a local flag standing in for an off-chain feed classification; an
  "unused field" style remark about it is the finding restated, not separate noise.
- `AdminCap` is transferred to the publisher in `init`; a "single admin key" note is out of
  scope (every setter is capability-gated by design; the class is what the setters allow).
- `is_liquidatable` has no caller inside the fixture; "dead code" remarks are out of scope.

## Build

```
cd tests/fixtures/c08-oracle-ratio-feed-misconfig
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
