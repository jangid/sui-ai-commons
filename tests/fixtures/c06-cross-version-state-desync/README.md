# Fixture: c06-cross-version-state-desync

## Class

C6 — Stale/legacy package still callable; cross-version state desync and no-patch-path.

## Mirrored incident

BlueMove DEX (Sui, 2026-07-11, ~700-714K SUI, about $0.5M): V1 and the latest version both
wrote `Pool.reserve_x` from different balance sources, the latest version's `mint` divided by
the V1-deflated reserve, and the `UpgradeCap` had been burned on 2026-06-03 so no patch path
existed. Secondary: Scallop (Sui, 2026-04-26) — a legacy spool package remained callable.
RS-001 catalog rows: BlueMove DEX 2026-07-11 and Scallop 2026-04-26
(`docs/research/RS-001-exploit-coverage-refresh/findings.md`, class C6 row of the coverage-gap
table and the Move section).

## Requirements

Acceptance evidence for REQ-COV-015, REQ-COV-016 and REQ-COV-017 (the C6 check contracts in
`docs/spec/coverage-checks.md`), and for REQ-COV-041 and REQ-COV-042 (fixture layout and README
contract in `docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- CHK-C6-1 (REQ-COV-015) — two live writers of one accounting field.
- CHK-C6-2 (REQ-COV-016) — immutability declared with a live legacy package.
- CHK-C6-3 (REQ-COV-017) — legacy entry points reachable from routers.

Both versions are present as sibling modules (`legacy`, `v2`) of one package so the
prior-version source is available and the `[ZD-EXT-UNVERIFIED]` limitation does not apply.

## Expected finding

- CHK-C6-1: `Pool.reserve_x` (and `reserve_y`) has two live writer lineages:
  `legacy::add_liquidity` / `legacy::swap_x_for_y` write it from `Pool.balance_x`, while
  `v2::deposit` writes it via `legacy::set_reserves` from `Vault.balance_x`. `v2::quote_mint`
  divides by the shared field, so a legacy swap that deflates it inflates the next V2 mint.
  Neither legacy writer is version-gated, so the carve-out does not apply. Confidence `likely`
  (both writers read); severity High.
- CHK-C6-2: `v2::make_immutable` calls `sui::package::make_immutable(upgrade_cap)` while
  `legacy::Pool` still holds `balance_x` / `balance_y` and `legacy::swap_x_for_y` is neither
  paused nor version-gated. Two-gate feasibility passes (reachability: the legacy entry point
  is `public`; math-bounds: pool balances and `reserve_x` pricing state are live), so severity
  is no lower than High. Confidence `confirmed` (grep seed `make_immutable` hits).
- CHK-C6-3: `legacy::swap_x_for_y` and `legacy::add_liquidity` are `public` functions that
  mutate the shared `Pool` with no version field check, pause flag or removed object type;
  routers and aggregators that address the package by ID can still route through them.
  Confidence `confirmed`; severity High.

## Expected noise

- `legacy::swap_x_for_y` uses a simplified constant-product formula with no fee and no
  k-invariant assert; "missing invariant check" or "no swap fee" remarks are incidental to the
  class and should not be counted against the fixture.
- `v2::quote_mint` uses a deliberately crude mint formula so that the division by the shared
  `reserve_x` is unmistakable; an "LP pricing math" note is the CHK-C6-1 sink, not a separate
  finding.
- `v2::make_immutable` is `AdminCap`-gated, so a generic "unguarded admin action" note is not
  expected; the finding is the immutability itself (CHK-C6-2).

## Build

```
cd tests/fixtures/c06-cross-version-state-desync
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
