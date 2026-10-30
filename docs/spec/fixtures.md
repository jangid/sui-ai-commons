---
status: Approved
last_updated: 2026-10-30
requires: [REQ-COV-041, REQ-COV-042]
---

# Vulnerable Move Fixtures

## Context

The auditor is a prompt; its checks cannot be unit-tested. Operator decision 8 therefore makes
compliance two-sided: instructing text at a cited heading (content-level, `coverage-checks.md`
and `perps-playbook.md`) and a minimal vulnerable Sui Move package per class that the check is
expected to flag (fixture-level, this spec). Fixtures are repository-level test data under
`tests/fixtures/`, outside `plugins/`, so they never ship to installed users and never affect
the plugin version. This spec fulfils REQ-COV-041 and REQ-COV-042.

A fixture is *acceptance evidence*, not a regression test: it proves the class is concrete
enough to be written in Move and gives a reviewer a target to run the auditor against by hand.

## Design

### Directory layout (REQ-COV-041)

```
tests/fixtures/
  README.md                         # index: slug → class → requirement IDs → expected finding (one table)
  <class-slug>/
    Move.toml
    Move.lock                       # committed (see Move.toml contract)
    README.md                       # per-fixture contract (REQ-COV-042)
    sources/
      <one or two>.move
```

No `tests/` directory inside a fixture (the fixture is the vulnerable code, not a test suite);
no shared `common/` package (each fixture must build in isolation so a reviewer can `cd` into
one directory and run `sui move build`).

### Class-slug list (concrete; nine fixtures, C19 exempt)

Slug format: `c<NN>-<kebab-mechanism>` for a numbered RS-001 class; `perps-<mechanism>` for the
archetype fixture that has no single class number. Two digits keep `ls` sorted by class.

| Slug | Class | Mirrored incident | Checks it is evidence for | Expected candidate (function or field) |
|---|---|---|---|---|
| `c03-signed-value-reinterpretation` | C3 | Aftermath Perps (Sui, 2026-04-28) | CHK-C3-1..3, PB-5 (REQ-COV-006..008, 038) | Fee field stored as raw `u256`/`u64` in a constructor without range check, decoded as signed fixed-point on the fee path into a collateral delta; cap compared in the unsigned domain |
| `c06-cross-version-state-desync` | C6 | BlueMove DEX (Sui, 2026-07-11) | CHK-C6-1..3 (REQ-COV-015..017) | Two modules (`legacy`, `v2`) both write `Pool.reserve_x` from different balance sources; an admin function calls `package::make_immutable` while `legacy` still holds funds; a `legacy` `public` entry point has no version gate |
| `c07-thin-collateral-recursive-borrow` | C7 | Tectonic (Cronos, 2026-08-30); YieldBlox | CHK-C7-1..4 (REQ-COV-018..021) | Collateral listing with no supply/borrow cap; `borrow` + `supply` of the same asset callable in one PTB with no per-asset loop bound; oracle adapter accepts a single last-trade price; permissionless `refresh_price` with no deviation gate |
| `c08-oracle-ratio-feed-misconfig` | C8 | Moonwell (Feb 2026); Aave CAPO | CHK-C8-1..3 (REQ-COV-022..024) | A ratio (LST/base) feed consumed as a USD price; `set_feed` with no sanity band; growth-cap setter that updates `ratio` without `ratio_timestamp` |
| `c09-oracle-authority-unpinned` | C9 | Full Sail (Sui, 2026-08-29); Ostium | CHK-C9-1..4 (REQ-COV-025..028) | Consumer stores only an aggregator object reference, never pins `object::id` or the expected queue/authority, accepts any single update with no per-update move bound; deposit and withdraw priced by the same feed with no cooldown |
| `c11-governance-capture` | C11 | BonkDAO; X100; Yapeswap | CHK-C11-0..5 (REQ-COV-009..014; CHK-C11-0 is evidenced by the README naming the trigger-grep hits and the six per-item outcomes the report must record individually) | `vote` reads live balance; `QUORUM = 0`; `execute` callable in the same tx as pass with no delay; payload is an arbitrary `(address, u64)` transfer; no vote-token lock |
| `c12-bridge-single-verifier` | C12 | KelpDAO (1-of-1 DVN); NEAR Intents refund | CHK-C12-1..3 (REQ-COV-029..031) | `VerifierSet { members: vector<address>, threshold: 1 }` accepted at construction; replay key is `nonce` only; `refund` pays `claimed_amount` not bounded by `deposited` |
| `c20-perps-market-manipulation` | C20 | Mars Perps; SecuredFi; Rocket Perp | PB-2..4 (REQ-COV-035..037) | `set_funding_rate` permissionless and unbounded; `match` has no `taker != maker` owner check and mark price taken from last fill; `set_maintenance_margin` with no open-position re-check |
| `perps-funding-settlement-ordering` | Perps archetype, C17 perps side | Perpetual Protocol v2 (2026-07-16); BiFi | PB-1 (REQ-COV-034) | `increase_position` / `add_collateral` mutate size/margin before `settle_funding` is called |

Decision: one fixture per class rather than one per requirement. Rationale: REQ-COV-041 is
phrased per class, and a single small module can exhibit three or four related omissions
without becoming unreadable; the README's expected-finding list enumerates each omission so a
reviewer can match them to requirement IDs. C3 is a perps-shaped fixture on purpose so that one
package is evidence for both the driver's C3 bullet and the perps playbook's sink rule.

### Fixture content rules

- **Minimal and vulnerable, not realistic.** Target 40–150 lines per fixture; no tests, no
  events required, no real oracle dependency (oracle objects are local stand-in structs with the
  same field *roles*: `authority`, `queue`, `price`, `timestamp`). Rationale: the auditor must
  flag the *mechanism*; depending on Pyth/Switchboard packages would make builds network- and
  version-fragile.
- **Compiles with zero warnings** under `sui move build` on Sui CLI 1.81.1 (the repository's
  stated reference toolchain; the driver itself demands zero warnings in Phase 1 step 7, so a
  warning-emitting fixture would trip the auditor on the wrong thing). Lints that the vulnerable
  shape unavoidably triggers (e.g. `self_transfer`) are silenced with a targeted `#[allow(...)]`
  and a comment saying why — never with `warnings = "allow"` in `Move.toml`.
- **The vulnerability is the only deviation.** Everything else follows the auditor's own
  guidance (named error constants, `&Clock`, capability-gated admin functions) so the expected
  candidate is the sole thing the check should surface. A fixture that also trips unrelated
  checks dilutes the acceptance signal; the per-fixture README lists any known incidental
  findings as "expected noise" so a reviewer does not count them as failures.
- **Illustrative shape (not normative).** For the C3 fixture, the module has roughly:

  ```move
  public struct IntegratorInfo has key, store { id: UID, taker_fee_raw: u256 }
  public fun create_integrator_info(fee: u256, ctx: &mut TxContext): IntegratorInfo // no range check
  fun taker_fee_signed(info: &IntegratorInfo): IFixed                                // reinterprets raw bits
  public fun process_fill(pos: &mut Position, info: &IntegratorInfo)                 // collateral -= fee (signed)
  ```

  Struct names and signatures are the implementer's; the roles (unchecked raw store, signed
  read, value sink) are the contract.

### `Move.toml` contract

```toml
[package]
name = "<class_slug_in_snake_case>"
edition = "2024"
# published-at deliberately absent: fixtures are never published

[addresses]
<class_slug_in_snake_case> = "0x0"
```

**Framework dependency decision [high-uncertainty].** Sui CLI 1.81.1 treats the Sui framework
(`Sui`, `MoveStdlib`, `Bridge`, `SuiSystem`) as *implicit* system dependencies matching the CLI's
own version; an explicit `[dependencies] Sui = { git = ... }` entry is redundant and, on recent
CLIs, emits a warning or a conflict. The dispatch asks for a pinned git dependency "to a tag or
`framework/testnet` branch". Resolution:

- **Default (what the implementer tries first):** rely on the implicit framework dependency —
  no `[dependencies]` table — and commit the generated `Move.lock`, which records the resolved
  framework version. This gives zero-warning builds and version pinning via the lock file.
- **Fallback (if the default emits a warning or fails on 1.81.1):** add
  `Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "testnet-v1.81.1" }`
  — a **tag**, not the moving `framework/testnet` branch, so that a reviewer six months later
  builds the same thing. If that tag does not exist, use `rev = "framework/testnet"` and record
  the resolved commit from `Move.lock` in the fixture README.
- **Spike S-2 (bounded, ≤ 4 tool calls, implement stage):** build `c11-governance-capture` with
  the default; if any warning mentions implicit dependencies or the build fails, switch all nine
  `Move.toml` files to the fallback and record which variant is in use in
  `tests/fixtures/README.md`. The variant is a single repository-wide decision, never mixed.

`Move.lock` is committed (`.gitignore` currently ignores only `.sdd/` and `.claude/worktrees/`;
no change needed).

### Per-fixture `README.md` contract (REQ-COV-042)

Fixed headings, in order:

1. `# Fixture: <slug>`
2. `## Class` — `C<NN> — <RS-001 label>` (or `Perps archetype (C17 perps side)`).
3. `## Mirrored incident` — protocol, chain, date, one-sentence mechanism, RS-001 catalog row
   reference.
4. `## Requirements` — the REQ-COV IDs this fixture is acceptance evidence for, and the check IDs
   (`CHK-*` / `PB-*`) from `coverage-checks.md` / `perps-playbook.md`.
5. `## Expected finding` — a bullet per omission: the condition the auditor should report and
   the exact `module::function` or `Struct.field` where it should be reported; the expected
   confidence tier and severity cap per `coverage-checks.md`.
6. `## Expected noise` — incidental candidates a correct run may also surface (may be "none").
7. `## Build` — `sui move build` from this directory; toolchain `sui 1.81.1`; dependency variant
   in use.

### Index `tests/fixtures/README.md`

One table with columns `Slug | Class | Incident | Requirement IDs | Expected candidate (short)`,
one row per fixture (nine rows), plus the C19 exemption note ("REQ-COV-039 is advisory and must
not produce a finding; no fixture") and the dependency-variant statement from spike S-2.

### Interaction with other specs

- `coverage-checks.md` / `perps-playbook.md` define the check IDs the READMEs cite; a check with
  no fixture row in the table above is a spec defect (every CHK-* and PB-* maps to exactly one
  slug, CHK-C19-1 exempt; `CAT-*` are catalog-row handles, not checks, and have no fixture).
  Verified in the table on 2026-10-30 after the review fix pass: CHK-C3-1..3, C6-1..3, C7-1..4,
  C8-1..3, C9-1..4, C11-0..5, C12-1..3, PB-1..5 — 31 IDs, each in exactly one row.
- `release-wiring.md` requires `CLAUDE.md` to mention `tests/fixtures/` and the compile command.
- Fixtures are not part of the plugin; adding or changing them never bumps `plugin.json`.

## Verification

### Automated

- `all_nine_fixture_dirs_exist`: `ls -d tests/fixtures/*/ | wc -l` is 9 and the names equal the
  slug list exactly.
- `each_fixture_builds_clean`:
  `rc=0; for d in tests/fixtures/*/; do out=$(cd "$d" && sui move build 2>&1) || rc=1; grep -qiE '^(warning|error)' <<<"$out" && rc=1; done; exit $rc`
  exits 0 — the build's own exit code and any warning/error line in **any** fixture (not only
  the last) fail the check.
- `each_fixture_has_move_toml_lock_readme_sources`: per directory, `Move.toml`, `Move.lock`,
  `README.md`, and ≥ 1 `sources/*.move` exist.
- `move_toml_has_no_published_at_and_edition_2024`: `grep -L published-at` lists all nine;
  `grep -l 'edition = "2024"'` lists all nine.
- `dependency_variant_uniform`: the count of `Move.toml` files containing `[dependencies]` is
  0 or 9, never in between.
- `readme_headings_fixed`: each fixture README contains the seven headings in order.
- `readme_cites_valid_ids`: every `REQ-COV-0NN` in a README exists in
  `docs/requirements/traceability.md`; every `CHK-`/`PB-` ID exists in the specs.
- `index_table_complete`: `tests/fixtures/README.md` has nine data rows whose slugs match the
  directories, and mentions `REQ-COV-039` with the word "exempt" or "no fixture".
- `no_plugin_files_touched_by_fixture_commits`: `git diff --name-only <base>..HEAD -- plugins/`
  is empty for commits that only add fixtures (checked at PR review).

### Manual

- For at least two fixtures (`c03-…` and `c09-…`), run `sui-ai:sui-move-auditor` from the
  fixture directory and confirm the report contains a candidate at the function/field named in
  `## Expected finding` with a confidence tier and severity no higher than the stated cap. This
  is a reviewer sanity check, not a gate (operator decision 8 makes compile + text the gate).

### Acceptance Criteria

- [ ] Nine fixture directories with the exact slugs above exist under `tests/fixtures/`, each
      with `Move.toml`, `Move.lock`, `README.md`, `sources/*.move` (REQ-COV-041).
- [ ] `sui move build` succeeds with zero warnings in every fixture on Sui CLI 1.81.1, using
      one dependency variant repository-wide, recorded in the index README (REQ-COV-041,
      spike S-2 closed).
- [ ] Each README follows the seven-heading contract and names class, incident, requirement
      IDs, check IDs, and the expected finding location (REQ-COV-042).
- [ ] The index README lists all nine fixtures and the C19 exemption (REQ-COV-041).
- [ ] Every CHK-* and PB-* ID in the specs (31, including CHK-C11-0) appears in exactly one
      fixture README (coverage of checks by fixtures), except CHK-C19-1 (exempt). `CAT-*` IDs
      are spec-only handles for false-positive catalog rows, not checks, and have no fixture.
- [ ] No file under `plugins/` is modified by the fixture additions; `plugin.json` version is
      unaffected by fixture-only commits.

## Implementation Questions

### Q-IMPL-001: `sui move build` output directory is untracked, not ignored
**Tier**: 2 (spec ambiguity)
**Spec reference**: §`Move.toml` contract — "`Move.lock` is committed (`.gitignore` currently
ignores only `.sdd/` and `.claude/worktrees/`; no change needed)"
**Decision**: each `sui move build` emits `<fixture>/build/` (compiled bytecode, several MB per
fixture) which the spec's directory layout does not list and `.gitignore` does not exclude.
Implementers delete `tests/fixtures/*/build/` after every build and never commit it; `.gitignore`
is outside the fixture chunks' write scope, so adding a `tests/fixtures/*/build/` ignore line is
left to the orchestrator (Chunk 8 or 9 may add it when `.gitignore` is in scope).
**Rationale**: committing `build/` would bloat the repository and could make the
`each_fixture_builds_clean` gate pass on stale bytecode; deleting it keeps the committed fixture
to exactly `Move.toml`, `Move.lock`, `README.md`, `sources/` as the layout section states.

### Q-IMPL-003: `Move.toml` template comment collides with the `published-at` gate
**Tier**: 2 (spec ambiguity)
**Spec reference**: §`Move.toml` contract (template comment `# published-at deliberately absent: fixtures
are never published`) versus §Automated `move_toml_has_no_published_at_and_edition_2024`
(`grep -L published-at` must list every fixture)
**Decision**: the fixture `Move.toml` files keep a comment with the same meaning but without the
literal token `published-at` ("No published address line on purpose: fixtures are never
published"), so the grep-based gate and the template intent both hold. Applied to all three
Chunk 6 fixtures (including the Chunk 0 `c11` scaffold); Chunks 7 and 8 use the same wording.
**Rationale**: the gate is a literal substring grep, so the template comment as written makes
every compliant fixture fail `move_toml_has_no_published_at_and_edition_2024`; changing the
comment text is the smallest fix and leaves the contract (no `published-at` key) intact.
