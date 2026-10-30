# Fixture: c09-oracle-authority-unpinned

## Class

C9 — Oracle authority / signer-set / keeper-price plausibility.

## Mirrored incident

Full Sail (Sui, 2026-08-29, ~$91K, protocol wound down): the attacker added a key they
controlled to a live Switchboard oracle (a signer-set / authority compromise on the oracle
side), pushed prices ~100x away from market, deposited, restored the prices and withdrew; the
consuming protocol pinned neither the aggregator's identity nor its authority and applied no
per-update plausibility bound. Virtue Money (IOTA Move, 2026-08-28, ~$0.455–0.89M, 45 users)
fell to the same Switchboard compromise. Secondary row for the signed-keeper mechanism:
Ostium (Arbitrum, 2026-07-15, ~$23.75M; the vault accepted signed keeper price reports with
no plausibility check). RS-001 catalog rows: Full Sail 2026-08-29, Virtue Money 2026-08-28,
Ostium 2026-07-15 (`docs/research/RS-001-exploit-coverage-refresh/findings.md`, class C9 row
of the coverage-gap table and the Move section).

## Requirements

Acceptance evidence for REQ-COV-025, REQ-COV-026, REQ-COV-027 and REQ-COV-028 (the C9 check
contracts in `docs/spec/coverage-checks.md`), and for REQ-COV-041 and REQ-COV-042 (fixture
layout and README contract in `docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- CHK-C9-1 (REQ-COV-025) — authority of consumed oracle objects pinned.
- CHK-C9-2 (REQ-COV-026) — minimum oracle count and per-update move bound.
- CHK-C9-3 (REQ-COV-027) — oracle-priced round trip within one staleness window.
- CHK-C9-4 (REQ-COV-028) — signed keeper reports carry a plausibility bound.

Spike S-1 outcome note: whichever way S-1 resolves the Switchboard row of the C9 provider
table (readable `authority` with authority-gated setters, or the fallback "pin aggregator ID +
queue ID + consumer-side staleness/variance"), this fixture violates the check — `Vault<T>`
pins neither the aggregator `object::id` nor the `queue` nor the `authority`.

## Expected finding

- CHK-C9-1: `Vault<T>` stores no `expected_aggregator`, `expected_queue` or
  `expected_authority`; the sole read path `vault::read_price` (called by `vault::deposit` and
  `vault::withdraw`) checks staleness only and never compares `object::id(agg)`, `agg.queue`
  or `agg.authority` with anything, so any `Aggregator` — including one whose authority was
  rotated through `vault::set_authority` / `vault::set_keeper` — is accepted. Enumeration: one
  consumed price-object type (`Aggregator`, custom / in-house row of the provider table: every
  writer is `authority`-gated, the cap holder is whoever `set_authority` names). Confidence
  `likely` (the oracle stand-in's source is in the same package, so the writer set is read);
  severity cap Medium pattern-only, High with the round-trip sequence below.
- CHK-C9-2: `vault::push_price` sets `Aggregator.price` from a single writer's single sample
  with no `min_sample_size` and no bound on the move from the previous value; the consumer
  asserts neither. Both controls absent ⇒ candidate at `vault::push_price` /
  `vault::read_price`. Confidence `likely` (static reading); severity cap Medium pattern-only;
  High once a single-sample price move is shown accepted on-chain or in a PTB trace.
- CHK-C9-3: `vault::deposit` mints `Shares<T>` at the current feed price and `vault::withdraw`
  redeems at the current feed price with no cooldown and no cumulative NAV-deviation breaker.
  Sequence inside one `MAX_STALENESS_MS` (60 s) window: `push_price(100x)` →
  `deposit(1 token)` mints 100x the fair shares → `push_price(1x)` → `withdraw` returns ~100
  tokens for 1 deposited. Confidence `likely` (window length and price move stated from
  source, not executed); severity cap Medium pattern-only; High once the round trip is replayed
  in a PTB trace inside one staleness window.
- CHK-C9-4: `vault::submit_report` verifies an ed25519 signature over `bcs(price)` against
  `Aggregator.keeper_pubkey` and then writes `price` unconditionally — signer identity only,
  no deviation check against the previous value or a second feed. Confidence `likely` (static
  reading); severity cap Medium pattern-only; High once a signed out-of-band price is shown
  written on-chain or in a PTB trace (the Ostium shape).

## Expected noise

- The `Aggregator` stand-in and its setters live in the consumer package only so the fixture
  builds in isolation; "oracle and consumer in one module" or "authority can rotate itself"
  remarks about the stand-in are incidental — the class is the consumer's missing pin and
  bound, which hold against a real third-party package too.
- `vault::create_vault` and `vault::create_aggregator` are permissionless constructors of
  shared objects; a "missing admin gate on creation" note is incidental.
- `Shares<T>` is a plain receipt with no fee or slippage logic; "no withdrawal fee" remarks are
  out of scope.

## Build

```
cd tests/fixtures/c09-oracle-authority-unpinned
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
