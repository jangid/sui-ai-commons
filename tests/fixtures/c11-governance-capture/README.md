# Fixture: c11-governance-capture

## Class

C11 — Governance capture (flash-loan voting power, zero quorum, malicious proposal, no
execution delay).

## Mirrored incident

BonkDAO (Solana, 2026-07-06, ~$20M): a malicious treasury-transfer proposal passed and executed
with flash-loan-inflated voting power against a trivially low quorum and no execution delay.
RS-001 catalog rows: BonkDAO 2026-07-06, Term Finance, X100 (`docs/research/RS-001-exploit-coverage-refresh/findings.md`,
class C11 row of the coverage-gap table).

## Requirements

Acceptance evidence for REQ-COV-009, REQ-COV-010, REQ-COV-011, REQ-COV-012, REQ-COV-013 and
REQ-COV-014 (the C11 check contracts in `docs/spec/coverage-checks.md`), and for REQ-COV-041
and REQ-COV-042 (fixture layout and README contract in `docs/spec/fixtures.md`).

Check IDs this fixture is a true positive for, each spelled out:

- CHK-C11-0 (REQ-COV-009) — trigger and per-check reporting. Trigger-grep hits in
  `sources/governance.move`: `propose` (function `governance::propose`), `vote` (function
  `governance::vote`, fields `yes_votes` / `no_votes`), `quorum` (constant `QUORUM`),
  `execute_proposal` (function `governance::execute_proposal`). No `cast` or `timelock` hit.
  The report must record the six governance items individually (CHK-C11-0 itself plus the
  five below) in the findings or verified-clean list; expected per-item outcomes: CHK-C11-0
  triggered (recorded), CHK-C11-1 finding, CHK-C11-2 finding, CHK-C11-3 finding,
  CHK-C11-4 finding, CHK-C11-5 finding. None is expected to land in the verified-clean list.
- CHK-C11-1 (REQ-COV-010) — snapshot before proposal.
- CHK-C11-2 (REQ-COV-011) — quorum and proposer threshold.
- CHK-C11-3 (REQ-COV-012) — execution delay with veto.
- CHK-C11-4 (REQ-COV-013) — restricted executable payload.
- CHK-C11-5 (REQ-COV-014) — vote tokens locked for the voting period.

## Expected finding

- CHK-C11-1: `governance::vote` reads `ballot.value()` — the live balance of the `Coin<GOV>`
  at vote time — with no snapshot or checkpoint taken before `propose`. Flash-loan-defeatable;
  cross-reference the Phase 1.1 flash-loan-reachable-state item. Confidence `likely`
  (the live-balance read and the missing snapshot are both in `governance::vote`); severity
  cap Medium pattern-only; High once a flash-loan-funded vote is shown on-chain or in a PTB
  trace.
- CHK-C11-2: `governance::QUORUM` is the absolute constant `0`, and `governance::propose`
  has no proposer threshold. Confidence `likely` (constant is literal; static reading); severity
  cap Medium pattern-only; High once a proposal passing with zero votes is shown on-chain or in
  a PTB trace.
- CHK-C11-3: `governance::execute_proposal` has no delay between pass and execution (it does not
  even check `voting_ends_ms`) and no guardian/veto path exists anywhere in the module; propose,
  vote and execute can run in a single PTB. Confidence `likely` (static reading); severity cap
  Medium pattern-only; High once propose, vote and execute are shown in one PTB (trace or
  replay).
- CHK-C11-4: `Proposal.target` / `Proposal.amount` form a generic `(address, u64)` treasury
  transfer executed by `governance::execute_proposal` via `transfer::public_transfer` — the
  Move shape of an arbitrary payload; no allow-list of actions. Confidence `likely` (static
  reading); severity cap Medium pattern-only; High once a treasury transfer executed through an
  arbitrary `(target, amount)` proposal is shown on-chain or in a PTB trace.
- CHK-C11-5: `governance::vote` borrows `&Coin<GOV>` and leaves no lock object, vote receipt or
  per-voter record, so the same coin can vote repeatedly from the same account before
  `voting_ends_ms` — a transfer to another address is not even needed. Not covered by the
  snapshot carve-out because CHK-C11-1 also fails. Confidence `likely`; severity cap Medium
  pattern-only; High once a repeat vote from one coin is shown on-chain or in a PTB trace
  (stacks with CHK-C11-1).

## Expected noise

- `governance::deposit` and `governance::propose` are permissionless by design; a report may
  list "no access control on propose" — that is the CHK-C11-2 proposer-threshold item, not a
  separate finding.
- `Treasury` is a shared object with an unbounded `Balance<SUI>`; a generic "shared treasury
  drain" note is expected and is the CHK-C11-4 sink, not an additional class.

## Build

```
cd tests/fixtures/c11-governance-capture
export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"
sui move build </dev/null
```

Toolchain `sui 1.81.1`. Dependency variant: implicit framework dependency (no `[dependencies]`
table in `Move.toml`; the committed `Move.lock` pins the framework resolved by the CLI). The
`build/` output directory is deleted after each build and is never committed.
