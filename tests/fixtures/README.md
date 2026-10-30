# Vulnerable Move Fixtures

Minimal, deliberately vulnerable Sui Move 2024 packages — one per RS-001 exploit class the
`sui-move-auditor` checks cover (`docs/spec/fixtures.md`). Each is acceptance evidence that the
class is concrete enough to write in Move and gives a reviewer a target to run the auditor
against by hand; none is a regression test and none is ever published. Build any fixture with
`cd tests/fixtures/<slug> && sui move build` (toolchain `sui 1.81.1`; see each fixture's
`## Build` section for the sandbox environment variables). Per-fixture READMEs follow the
seven-heading contract in `docs/spec/fixtures.md` and spell out every check ID they are evidence
for.

| Slug | Class | Incident | Requirement IDs | Expected candidate (short) |
|---|---|---|---|---|
| `c03-signed-value-reinterpretation` | C3 — signed-value reinterpretation | Aftermath Perps (Sui, 2026-04-28) | REQ-COV-006, REQ-COV-007, REQ-COV-008, REQ-COV-038 (CHK-C3-1..3, PB-5) | Raw `u256` fee stored unchecked, read as signed into the collateral sink; cap compared in the unsigned domain |
| `c06-cross-version-state-desync` | C6 — cross-version state desync | BlueMove DEX (Sui, 2026-07-11) | REQ-COV-015, REQ-COV-016, REQ-COV-017 (CHK-C6-1..3) | `legacy` and `v2` both write `Pool.reserve_x`; `make_immutable` while `legacy` holds funds; ungated `legacy` entry point |
| `c07-thin-collateral-recursive-borrow` | C7 — thin collateral / recursive borrow | Tectonic (Cronos, 2026-08-30); YieldBlox | REQ-COV-018, REQ-COV-019, REQ-COV-020, REQ-COV-021 (CHK-C7-1..4) | No supply/borrow cap; same-asset borrow + supply loop in one PTB; single last-trade price; ungated `refresh_price` |
| `c08-oracle-ratio-feed-misconfig` | C8 — oracle misconfiguration | Moonwell (Base, 2026-02-15); Aave CAPO | REQ-COV-022, REQ-COV-023, REQ-COV-024 (CHK-C8-1..3) | Ratio feed consumed as USD; `set_feed` with no sanity band; cap setter updates `ratio` without `ratio_timestamp` |
| `c09-oracle-authority-unpinned` | C9 — oracle authority unpinned | Full Sail (Sui, 2026-08-29); Ostium | REQ-COV-025, REQ-COV-026, REQ-COV-027, REQ-COV-028 (CHK-C9-1..4) | Aggregator reference without pinned id / queue / authority; unbounded single update; deposit and withdraw on one feed with no cooldown |
| `c11-governance-capture` | C11 — governance capture | BonkDAO (Solana, 2026-07-06); X100; Yapeswap | REQ-COV-009, REQ-COV-010, REQ-COV-011, REQ-COV-012, REQ-COV-013, REQ-COV-014 (CHK-C11-0..5) | `vote` reads live balance; `QUORUM = 0`; same-tx `execute`; arbitrary `(address, u64)` payload; no vote-token lock |
| `c12-bridge-single-verifier` | C12 — bridge verification | KelpDAO (2026-04-18); Liquid; NEAR Intents | REQ-COV-029, REQ-COV-030, REQ-COV-031 (CHK-C12-1..3) | `VerifierSet { members: [x], threshold: 1 }` accepted; replay key is `nonce` only; `refund` pays `claimed_amount` unbounded by the deposit |
| `c20-perps-market-manipulation` | C20 — market manipulation | Mars Perps (2025-12-14); SecuredFi; Rocket Perp | REQ-COV-035, REQ-COV-036, REQ-COV-037 (PB-2..4) | Permissionless unbounded `set_funding_rate`; `match_orders` compares account ids and takes mark from the last fill; `set_maintenance_margin` with no open-position re-check |
| `perps-funding-settlement-ordering` | Perps archetype (C17 perps side) | Perpetual Protocol v2 (Optimism, 2026-07-16); BiFi | REQ-COV-034 (PB-1) | `increase_position` / `add_collateral` mutate size / margin before `settle_funding` |

C19 exemption: REQ-COV-039 is advisory and must not produce a finding; no fixture (its check id
therefore appears in no fixture README). `CAT-*` ids are false-positive catalog handles, not
checks, and have no fixture either.

Dependency variant (spike S-2, Sui CLI 1.81.1, 2026-10-30): every fixture uses the **implicit**
framework dependency — no `[dependencies]` table in `Move.toml`; the CLI supplies `Sui` and
`MoveStdlib` from its own release and the committed `Move.lock` pins the resolved framework
commit (`83f11dc85d5695a57894329b005b78d75f9bb059`, `use_environment = "testnet"`). Never mix in
an explicit `Sui = { git = ... }` line; the variant is a single repository-wide decision.
