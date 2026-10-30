# Fixture: c03-signed-value-reinterpretation

## Class

C3 — Signed-value reinterpretation / negative parameter accepted.

## Mirrored incident

Aftermath Finance Perps (Sui, 2026-04-28/29, ~$1.14M USDC): an integrator fee was stored as a
raw `u256` in `IntegratorInfo` and read back as signed `ifixed` in `calculate_taker_fees`, so
`2^256 - 10^23` decoded as a fee of -100,000 and was credited to the attacker's collateral.
RS-001 catalog row: Aftermath Perps 2026-04-28/29
(`docs/research/RS-001-exploit-coverage-refresh/findings.md`, class C3 row of the coverage-gap
table and the Move section).

## Requirements

Acceptance evidence for REQ-COV-006, REQ-COV-007 and REQ-COV-008 (the C3 check contracts in
`docs/spec/coverage-checks.md`), REQ-COV-038 (the perps playbook sink rule in
`docs/spec/perps-playbook.md`), and for REQ-COV-041 and REQ-COV-042 (fixture layout and README
contract in `docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- CHK-C3-1 (REQ-COV-006) — identify the candidates (raw-bits stored, signed-read).
- CHK-C3-2 (REQ-COV-007) — validation at the write boundary.
- CHK-C3-3 (REQ-COV-008) — caps compared in the consuming domain.
- PB-5 (REQ-COV-038) — fee, funding and collateral deltas as signed-value sinks (the playbook
  supplies `Position.collateral` as the sink set; the mechanism check is CHK-C3-1).

## Expected finding

- CHK-C3-1: `IntegratorInfo.taker_fee_raw` is written as unsigned `u256` by
  `perps_fees::create_integrator_info` and read as signed `IFixed` by
  `perps_fees::taker_fee_signed` on the path `process_fill -> mul_notional -> Position.collateral`.
  Grep seeds that hit: `IFixed`, `is_negative`, `SIGN_BIT`, `negative_magnitude`. Confidence
  `likely` (constructor-to-sink path traced in one module); severity cap Medium pattern-only,
  High with the algebraic example below.
- CHK-C3-2: `perps_fees::create_integrator_info` performs no range or sign check on `fee`; the
  constructor is `public`, so the "callers validate" carve-out does not apply. Confidence
  `confirmed`; severity High.
- CHK-C3-3: in `perps_fees::process_fill` the cap `fee.bits <= MAX_FEE_PER_FILL` is evaluated
  in the unsigned domain and only on the non-negative branch; a value with the sign bit set
  skips it and is credited as an uncapped rebate. Algebraic example (u256, two's complement):
  `taker_fee_raw = 2^256 - 10^23` reads as `-100,000 * 10^18`; for `notional = 10^18` the fee
  is `-10^23`, so `Position.collateral` increases by `10^23` (100,000 collateral units) with no
  cap applied. Confidence `confirmed`; severity High.
- PB-5: `Position.collateral` in `perps_fees::process_fill` is the collateral-delta sink the
  playbook names; the report should cite it as the sink of the CHK-C3-1 trace rather than as a
  separate finding.

## Expected noise

- `perps_fees::open_position` and `perps_fees::create_integrator_info` are permissionless
  constructors returning owned objects; a "missing admin gate on integrator creation" note may
  appear. It is incidental: the class is the domain mismatch, which an admin-gated constructor
  with the same body would still exhibit.
- `IFixed` and its helpers are a local stand-in, not a real fixed-point library; "unaudited
  math library" remarks are out of scope.

## Build

```
cd tests/fixtures/c03-signed-value-reinterpretation
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
