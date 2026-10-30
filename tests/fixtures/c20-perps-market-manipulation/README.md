# Fixture: c20-perps-market-manipulation

## Class

C20 — Market manipulation (funding-rate arbitrage, same-block self-trade on a thin book,
risk-parameter abuse).

## Mirrored incident

Mars Perps (Neutron, 2025-12-14, ~$0.96M): funding-rate arbitrage against a rate an
unprivileged caller could move and harvest within one interval. SecuredFi (Ethereum,
2026-09-05, ~$0.1M): a same-block self-trade moved the settlement price. Rocket Perp
(2026-09-05, ~$0.29M): risk-parameter abuse turned open positions liquidatable. RS-001 catalog
rows: Mars Perps 2025-12-14, SecuredFi 2026-09-05, Rocket Perp 2026-09-05
(`docs/research/RS-001-exploit-coverage-refresh/findings.md`, class C20 row of the coverage-gap
table).

## Requirements

Acceptance evidence for REQ-COV-035, REQ-COV-036 and REQ-COV-037 (the PB-2, PB-3 and PB-4
check contracts in `docs/spec/perps-playbook.md`), and for REQ-COV-041 and REQ-COV-042 (fixture
layout and README contract in `docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- PB-2 (REQ-COV-035) — funding-rate updates permissioned or bounded.
- PB-3 (REQ-COV-036) — self-trade on thin books moves the settlement price.
- PB-4 (REQ-COV-037) — risk-parameter changes re-check open positions.

## Expected finding

- PB-2: `market::set_funding_rate` takes no capability, applies no `rate <= MAX` cap and no
  per-interval change bound before writing `Market.funding_rate`; the harvest path is
  `market::settle_funding`, which credits the non-paying side `size * funding_rate / SCALE` in
  the same interval (funding-manipulation window: one `set_funding_rate` + one
  `settle_funding` in a single PTB). Confidence `confirmed`; severity High.
- PB-3: `market::match_orders` (named so because `match` is a Move 2024 keyword) guards
  self-matching with `object::id(taker) != object::id(maker)` — account IDs, not
  `Account.owner` addresses — so two accounts of one owner pass; and it writes
  `Market.mark_price = price` from the raw last fill with no EMA/TWAP or deviation bound against
  an index, so that price feeds `market::liquidate` and `market::remove_margin`. Both halves
  are absent; report both. Confidence `confirmed`; severity High.
- PB-4: `market::set_maintenance_margin` writes `Market.maintenance_margin_bps` immediately with
  no re-check of open `Account`s, no transition window and no bounded step; a position healthy
  under the old threshold is instantly liquidatable via `market::liquidate`. Confidence
  `confirmed`; severity Medium (admin-origin; cross-reference the driver's **Admin-origin latent
  user DoS**).

## Expected noise

- `market::open_account` is permissionless and lets one address hold many accounts; that is
  the precondition of the PB-3 self-match item, not a separate finding.
- `market::set_maintenance_margin` is capability-gated; a "trusted admin" trust-model note is
  expected and is not the PB-4 finding (the finding is the missing re-check).
- `Market.mark_price` is also never compared with an index price — any "mark ≠ index" note is
  part of PB-3, not an extra class.

## Build

```
cd tests/fixtures/c20-perps-market-manipulation
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
