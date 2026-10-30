# Fixture: c12-bridge-single-verifier

## Class

C12 — Bridge / cross-chain verification (single verifier, nonce-only replay key, refund larger
than deposit).

## Mirrored incident

KelpDAO rsETH LayerZero OFT (Ethereum / Unichain, 2026-04-18, ~$290M): the OApp was configured
with one required DVN and no optional DVNs, so a single poisoned verifier signed a fabricated
116,500 rsETH burn and the endpoint only checked the payload hash. Liquid Network (2026-09-06,
~$320M) was an unbacked federation mint of the same class; NEAR Intents HOT Bridge vault
(2026-09-30, ~$3.87M) accepted a refund request larger than the deposit when the resolution
callback broke. RS-001 catalog rows: KelpDAO 2026-04-18, Liquid Network 2026-09-06, NEAR Intents
2026-09-30 (`docs/research/RS-001-exploit-coverage-refresh/findings.md`, class C12 row of the
coverage-gap table).

## Requirements

Acceptance evidence for REQ-COV-029, REQ-COV-030 and REQ-COV-031 (the C12 check contracts in
`docs/spec/coverage-checks.md`), and for REQ-COV-041 and REQ-COV-042 (fixture layout and README
contract in `docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- CHK-C12-1 (REQ-COV-029) — verifier quorum of independent operators.
- CHK-C12-2 (REQ-COV-030) — replay protection beyond a nonce.
- CHK-C12-3 (REQ-COV-031) — refund never exceeds deposit; failed callbacks are inert.

## Expected finding

- CHK-C12-1: `VerifierSet.members` / `VerifierSet.threshold` are accepted by `bridge::create`
  with only a non-empty check, so `members = [x], threshold = 1` is a valid configuration and
  `bridge::attest` releases vault funds on that single attestation. The set authorises
  value-moving messages (reachability) and the whole `Bridge.vault` is reachable with one key
  (math bounds), so the two-gate check passes. Confidence `likely` (the configuration is
  constructor-time, not a literal constant); severity cap Medium pattern-only; High once the
  deployed `VerifierSet` is read on-chain with a single member or `threshold == 1`, regardless
  of operator reputation.
- CHK-C12-2: `Bridge.used_nonces` is keyed by `nonce` alone and `bridge::attest` overwrites
  `Pending.recipient` / `Pending.amount` with each attester's payload — nothing binds the
  attestations to a hash of `(nonce, recipient, amount)`, so a stale or fabricated payload under
  a fresh nonce is paid. Cross-reference the existing **Nonce replay** signature bullet.
  Confidence `likely` (static reading); severity cap Medium pattern-only; High once a replayed or
  substituted payload under a fresh nonce is shown paid (on-chain trace or PTB replay).
- CHK-C12-3: `bridge::refund` removes the recorded deposit but pays `claimed_amount`, bounded
  only by `Bridge.vault`; the `deposited <= claimed_amount` invariant is absent. Confidence
  `likely` (static reading); severity cap Medium pattern-only; High once a refund exceeding the
  recorded deposit is shown on-chain or in a PTB trace (loss capped by the vault balance).

## Expected noise

- `bridge::deposit` is permissionless by design; a "no access control on deposit" note is not a
  finding.
- `Bridge` is a shared object holding an unbounded `Balance<SUI>`; a generic "shared vault
  drain" note is the CHK-C12-3 sink, not an additional class.

## Build

```
cd tests/fixtures/c12-bridge-single-verifier
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
