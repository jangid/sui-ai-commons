This change lands on `main` directly by maintainer decision (kickoff operator decision 10): no
feature branch and no pull request are opened this cycle, and `main` is pushed at DONE. This
document is kept as the release note and rationale record for the change set.

## Why

RS-001 (`docs/research/RS-001-exploit-coverage-refresh/findings.md`, cutoff **2026-10-30**,
first-run window 2025-10-30 through 2026-10-30 inclusive) surveyed the past year of DeFi exploits
across eleven ranked sources and mapped them onto twenty-five root-cause classes (C1–C25). Nine
of those classes were either uncovered or only implicitly covered by `sui-move-auditor` v2.2.0:
signed-value reinterpretation (C3), cross-version state desync after package upgrades (C6), thin
collateral and recursive borrowing (C7), oracle feed misconfiguration (C8), unpinned oracle
authority (C9), governance capture (C11), single-verifier bridges (C12), platform/VM advisory
context (C19) and the perpetuals/margin archetype (C17 perps side, C20). This change closes those
gaps with generalized, grep-seeded checks (never protocol-specific rules), ships a new
`defi-perps-and-margin.md` playbook, records the source list and rerun procedure durably in
`docs/exploit-sources.md`, and adds nine compiling vulnerable Move fixtures as acceptance
evidence. Every new check obeys candidate ≠ finding, the absence rule and the Medium cap on
pattern-only evidence (operator decision 5).

## Audit-behaviour rationale

| Class | Check IDs | File → heading | What the auditor now does differently | Incident(s) it would have caught |
|---|---|---|---|---|
| C3 | CHK-C3-1, CHK-C3-2, CHK-C3-3 | `sui-move-auditor.md` → `### 5.3a High-signal correctness greps (cheap, high severity)`; sinks in `defi-perps-and-margin.md` → `## Fees, funding and collateral deltas as signed-value sinks` | Enumerates every numeric field written as unsigned and read as signed (`IFixed`, `is_negative`, `from_bits`), requires validation at the write boundary and caps compared in the consuming domain; reports the constructor-to-sink path | Aftermath Perps (Sui, 2026-04-28) |
| C6 | CHK-C6-1, CHK-C6-2, CHK-C6-3 | `sui-move-auditor.md` → `### 6.14 Package Upgrade Safety` | Three new items: two live writers of one accounting field, immutability declared while a legacy package still holds funds (floor High), legacy entry points reachable through routers/aggregators | BlueMove DEX (Sui, 2026-07-11) |
| C7 | CHK-C7-1, CHK-C7-2, CHK-C7-3, CHK-C7-4 | `defi-lending-and-liquidation.md` → `## Market creation & configuration validation` (**Collateral listing quality**) and `## Oracle staleness & price representability`; `sui-move-auditor.md` → `### 7.2 Oracle & Price Manipulation` | Walks every listed collateral asset: caps justified against liquidity depth (with a `needs_review` path when depth is unknown), recursive borrow-and-re-supply bounded, single-fill prices rejected; permissionless NAV/price refresh must be TWAP/deviation-gated | Tectonic (Cronos, 2026-08-30); YieldBlox |
| C8 | CHK-C8-1, CHK-C8-2, CHK-C8-3 | `defi-lending-and-liquidation.md` → `## Oracle staleness & price representability` | Classifies every consumed feed as ratio vs. absolute and requires composition with a base feed, a sanity band on feed-config changes, and coupled cap parameters updated atomically | Moonwell (Base, 2026-02-15); Aave CAPO |
| C9 | CHK-C9-1, CHK-C9-2, CHK-C9-3, CHK-C9-4 | `sui-native-pitfalls.md` → `## Oracle integrations (Pyth / Switchboard / custom feeds)` (new section + provider table); `sui-move-auditor.md` → `### 7.2 Oracle & Price Manipulation` (load bullet) and COMPANION REFERENCES row | Enumerates every third-party price-object type and checks that its id / queue / authority is pinned per provider (Pyth: `get_price_identifier`; Switchboard: aggregator + queue + authority, spike S-1 Outcome A), minimum oracle count and per-update move bound, no oracle-priced round trip inside one staleness window, plausibility bound on signed keeper reports | Full Sail (Sui, 2026-08-29); Ostium |
| C11 | CHK-C11-0, CHK-C11-1, CHK-C11-2, CHK-C11-3, CHK-C11-4, CHK-C11-5 | `sui-move-auditor.md` → `### 6.8 Governance, Voting & Weight Safety` (renamed from Weight & Governance Safety) | Governance trigger line runs five items individually: snapshot strictly before proposal, quorum floor > 0 plus proposer threshold, execution delay with veto/guardian, allow-listed payload, vote tokens locked for the voting period; each outcome recorded separately | BonkDAO (Solana, 2026-07-06); X100; Yapeswap |
| C12 | CHK-C12-1, CHK-C12-2, CHK-C12-3 | `sui-native-pitfalls.md` → `## Cross-chain / bridge / ZK` | Requires a verifier quorum of independent operators (1-of-1 or single-operator sets are no lower than High only after the two-gate check, Medium pattern-only), replay protection tied to the full message hash rather than a nonce alone, and refunds bounded by the deposit with inert failed callbacks | KelpDAO (2026-04-18); Liquid; NEAR Intents |
| C19 | CHK-C19-1 | `sui-move-auditor.md` → `## PHASE 1 — CONTEXT GATHERING` (new step 10) | Records the pinned framework/protocol version and known platform advisories as context; advisory only, never produces a finding (REQ-COV-039, no fixture) | Platform/VM-level incidents in the RS-001 corpus (context, not a finding class) |
| perps / C17 / C20 | PB-1, PB-2, PB-3, PB-4, PB-5 | `defi-perps-and-margin.md` (new playbook, loaded together with `defi-lending-and-liquidation.md`; wired via COMPANION REFERENCES and PHASE 8B) | Settle funding before any position/collateral mutation (a mutator with no `Clock`/index parameter cannot settle), funding-rate writers capability-gated or bounded with a reported manipulation window, self-match guard on owner addresses with smoothed/bounded mark price, risk-parameter setters re-check open positions or use a transition window, perps value sinks handed to the driver's 5.3a signed-value check | Perpetual Protocol v2 (Optimism, 2026-07-16); BiFi; Mars Perps (2025-12-14); SecuredFi; Rocket Perp; Aftermath Perps (sinks) |

## Content-level evidence (REQ-COV-040)

Every check id lands at a grep-able heading with a bold lead-in; the "first words" column is the
bullet's lead-in as it appears in the tree (`$D` = `plugins/sui-ai/agents/sui-move-auditor.md`,
`$P` = `plugins/sui-ai/agents/sui-move-auditor/`).

| CHK-ID | file | heading | first words |
|---|---|---|---|
| CHK-C3-1 | `$D` | `### 5.3a High-signal correctness greps (cheap, high severity)` | **Raw-bits stored, signed-read (domain reinterpretation).** |
| CHK-C3-2 | `$D` | `### 5.3a High-signal correctness greps (cheap, high severity)` | **Validation at the write boundary.** |
| CHK-C3-3 | `$D` | `### 5.3a High-signal correctness greps (cheap, high severity)` | **Caps compared in the consuming domain.** |
| CHK-C6-1 | `$D` | `### 6.14 Package Upgrade Safety` | **Two live writers of one accounting field:** |
| CHK-C6-2 | `$D` | `### 6.14 Package Upgrade Safety` | **Immutability declared (`make_immutable` / `UpgradeCap` burn) with a live legacy package, floor High:** |
| CHK-C6-3 | `$D` | `### 6.14 Package Upgrade Safety` | **Legacy entry points reachable through routers/aggregators:** |
| CHK-C7-1 | `$P/defi-lending-and-liquidation.md` | `## Market creation & configuration validation` → **Collateral listing quality** | Caps justified against liquidity depth |
| CHK-C7-2 | `$P/defi-lending-and-liquidation.md` | `## Market creation & configuration validation` → **Collateral listing quality** | Recursive borrow-and-re-supply bounded |
| CHK-C7-3 | `$P/defi-lending-and-liquidation.md` | `## Oracle staleness & price representability` | **Single-fill prices rejected.** |
| CHK-C7-4 | `$D` | `### 7.2 Oracle & Price Manipulation` | **Permissionless NAV/AUM/price refresh** |
| CHK-C8-1 | `$P/defi-lending-and-liquidation.md` | `## Oracle staleness & price representability` | **Ratio feeds composed with a base feed.** |
| CHK-C8-2 | `$P/defi-lending-and-liquidation.md` | `## Oracle staleness & price representability` | **Sanity band on feed changes.** |
| CHK-C8-3 | `$P/defi-lending-and-liquidation.md` | `## Oracle staleness & price representability` | **Coupled cap parameters move together.** |
| CHK-C9-1 | `$P/sui-native-pitfalls.md` (+ `$D` → `### 7.2` load bullet **Consumed-feed authority and plausibility.**) | `## Oracle integrations (Pyth / Switchboard / custom feeds)` | **Authority of consumed oracle objects.** |
| CHK-C9-2 | `$P/sui-native-pitfalls.md` | `## Oracle integrations (Pyth / Switchboard / custom feeds)` | **Minimum oracle count and per-update move bound.** |
| CHK-C9-3 | `$P/sui-native-pitfalls.md` | `## Oracle integrations (Pyth / Switchboard / custom feeds)` | **Oracle-priced round trip within one staleness window.** |
| CHK-C9-4 | `$P/sui-native-pitfalls.md` | `## Oracle integrations (Pyth / Switchboard / custom feeds)` | **Signed keeper reports carry a plausibility bound.** |
| CHK-C11-0 | `$D` | `### 6.8 Governance, Voting & Weight Safety` | trigger line (`propose\|vote\|cast\|quorum\|execute_proposal\|timelock`) … record each outcome individually |
| CHK-C11-1 | `$D` | `### 6.8 Governance, Voting & Weight Safety` | **Voting power read from a snapshot taken strictly before proposal creation** |
| CHK-C11-2 | `$D` | `### 6.8 Governance, Voting & Weight Safety` | **Quorum floor > 0, relative to total voting supply, and proposer threshold > 0:** |
| CHK-C11-3 | `$D` | `### 6.8 Governance, Voting & Weight Safety` | **Execution delay with veto:** |
| CHK-C11-4 | `$D` | `### 6.8 Governance, Voting & Weight Safety` | **Allow-listed executable payload:** |
| CHK-C11-5 | `$D` | `### 6.8 Governance, Voting & Weight Safety` | **Vote tokens locked for the voting period:** |
| CHK-C12-1 | `$P/sui-native-pitfalls.md` | `## Cross-chain / bridge / ZK` | **Verifier quorum of independent operators.** |
| CHK-C12-2 | `$P/sui-native-pitfalls.md` | `## Cross-chain / bridge / ZK` | **Replay protection beyond a nonce.** |
| CHK-C12-3 | `$P/sui-native-pitfalls.md` | `## Cross-chain / bridge / ZK` | **Refund never exceeds deposit; failed callbacks are inert.** |
| CHK-C19-1 | `$D` | `## PHASE 1 — CONTEXT GATHERING` | 10. **Platform / VM advisory context.** |
| PB-1 | `$P/defi-perps-and-margin.md` | `## Funding settlement ordering` | **Settle funding before any position or collateral change.** |
| PB-2 | `$P/defi-perps-and-margin.md` | `## Funding-rate updates: permissioned or bounded` | **Every funding-rate or funding-index writer is capability-gated or bounded.** |
| PB-3 | `$P/defi-perps-and-margin.md` | `## Self-trade and mark-price manipulation on thin books` | **Self-match guard compares owner addresses, not account IDs.** |
| PB-4 | `$P/defi-perps-and-margin.md` | `## Risk-parameter changes and open positions` | **Every risk-parameter setter re-checks open positions or uses a transition window.** |
| PB-5 | `$P/defi-perps-and-margin.md` | `## Fees, funding and collateral deltas as signed-value sinks` | **Perps value sinks for the driver's signed-value check.** |

Four false-positive catalog rows (`CAT-*`: fee-on-transfer, approval races, proxy/delegatecall,
TSS/off-chain crypto) were added to `verification-and-false-positives.md` →
`## Move-specific false-positive catalog ("looks vulnerable, is safe")`; they are handles, not
checks, and have no fixture.

## Version

`plugins/sui-ai/.claude-plugin/plugin.json` `version`: **2.2.0 → 2.3.0**. A new companion
playbook plus roughly twenty new checks is a feature addition; the agent's invocation, its
manifest shape (no `agents`/`commands` field) and every existing heading the companion table
points at are unchanged, so nothing justifies a major bump, and REQ-REL-012 forbids a patch bump
for new behaviour. Exactly one bump for the whole change set, carried by the commit that ships
the plugin content (see the commit-shape note below). `.claude-plugin/marketplace.json` is
byte-identical to `main`.

## Non-plugin artifacts

- `docs/exploit-sources.md` (repo-level, outside `plugins/`): eleven ranked sources with full
  field blocks, the primary set (DefiLlama hacks API, rekt.news leaderboard, SlowMist hacked
  archive) with date-filter fields, the retry list for sources not verified this run, and the
  manual rerun procedure (strict `date > cutoff_prev` rule, `$1M`/`$10M` thresholds, C1–C25
  mapping, new `RS-00N` per rerun). No automation (`scripts/`, `.github/`) is shipped.
- `tests/fixtures/` — nine deliberately vulnerable Sui Move 2024 packages
  (`c03-signed-value-reinterpretation`, `c06-cross-version-state-desync`,
  `c07-thin-collateral-recursive-borrow`, `c08-oracle-ratio-feed-misconfig`,
  `c09-oracle-authority-unpinned`, `c11-governance-capture`, `c12-bridge-single-verifier`,
  `c20-perps-market-manipulation`, `perps-funding-settlement-ordering`) plus an index README.
  Compile result: **nine of nine build clean** (`sui move build`, exit 0, no `warning`/`error`
  line) on toolchain **`sui 1.81.1`** (`sui 1.81.1-e04cf9aa915c`). Dependency variant (spike
  S-2): **implicit framework** — no `[dependencies]` table in any `Move.toml`; the committed
  `Move.lock` pins the resolved framework to rev **`83f11dc8`**
  (`83f11dc85d5695a57894329b005b78d75f9bb059`, `use_environment = "testnet"`), so rebuilds are
  offline and reproducible. No fixture carries `published-at` or `warnings = "allow"`; every
  README follows the seven-heading contract and spells out each of the 31 CHK-*/PB-* ids exactly
  once across the set (CHK-C19-1 is exempt and appears in no fixture).
- `CLAUDE.md` (new, repo-level): layout, the five enumeration sites, `tests/fixtures` and
  `docs/exploit-sources.md` pointers.
- Manual auditor runs (optional, operator decision 8) were **not run** by the pipeline: a
  non-interactive subagent cannot dispatch the `sui-ai:sui-move-auditor` agent. Left for the
  operator; expected candidate locations from the fixture READMEs:
  - `tests/fixtures/c03-signed-value-reinterpretation`: `perps_fees::create_integrator_info`
    (unchecked `u256` `taker_fee_raw`), `perps_fees::taker_fee_signed` →
    `process_fill` → `Position.collateral` (CHK-C3-1..3, PB-5).
  - `tests/fixtures/c09-oracle-authority-unpinned`: `vault::read_price` (no pinned
    aggregator/queue/authority), `vault::push_price` (single unbounded writer),
    `vault::deposit`/`vault::withdraw` (round trip inside `MAX_STALENESS_MS`),
    `vault::submit_report` (signed report without plausibility bound) (CHK-C9-1..4).
  - `tests/fixtures/c11-governance-capture`: `governance::vote` (live balance, no lock),
    `QUORUM = 0`, `governance::execute_proposal` (no delay/veto, arbitrary `(address, u64)`
    payload) (CHK-C11-1..5).
  - `tests/fixtures/c20-perps-market-manipulation`: `market::set_funding_rate` (ungated,
    unbounded), `market::match_orders` (account-id self-match guard, raw last-fill mark),
    `market::set_maintenance_margin` (no open-position re-check) (PB-2..4); the run should
    report both the lending and the perps playbooks as loaded.
  All candidates should surface at severity ≤ Medium on pattern evidence alone; the READMEs state
  the code-path evidence that lifts each to High.

## Checklist

- [x] Both manifests parse (`python3 -m json.tool` on `plugins/sui-ai/.claude-plugin/plugin.json`
      and `.claude-plugin/marketplace.json`).
- [x] Five enumeration sites updated to include perps (driver frontmatter `description`,
      COMPANION REFERENCES table, PHASE 8B, Appendix C item 8, `CLAUDE.md` archetype list); no
      stale `vaults/AMM/lending/staking` enumeration remains in `plugins/` or `CLAUDE.md`.
- [x] `.claude-plugin/marketplace.json` `renames` untouched (file byte-identical to `main`).
- [x] `no_bare_companion_mention` clean: every companion-file mention in the driver and the
      companions uses `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md`; the companion
      table has seven full-path rows; no relative or `plugins/sui-ai/` paths inside the plugin.
- [x] Wrapped name/path lines confirmed by eye: the 7.2 load bullet carries no `|` after the
      `sui-native-pitfalls.md` path (so `sui_native_load_condition_mentions_oracle` matches the
      companion-table row exactly once), and every new driver bullet is ≤ 6 wrapped lines, every
      playbook bullet ≤ 8, each with a bold lead-in on the bullet line.
- [x] `## Self-liquidation & self-match` in `defi-lending-and-liquidation.md` is unchanged
      against `main` (`lending_margin_content_untouched`).
- [x] Nine of nine fixtures build clean; traceability has no empty Test/Implementation cell on
      the 72 live rows.

## Commit shape (for the orchestrator)

Operator decision 10 (kickoff) supersedes steps 1 and 4 below for this cycle: commits land on
`main` directly and no PR is opened; `branch_prefix` and `pr_exists_to_main_with_rationale_table`
are therefore waived this cycle, while steps 2 and 3 still apply. Steps 1 and 4 are retained as
the default for future cycles.

Requirements the commit split must satisfy at commit time (release-wiring.md
`bump_commit_subject_names_version`, `bump_and_content_same_commit`,
`non_plugin_commits_do_not_bump`, `branch_prefix`, `pr_exists_to_main_with_rationale_table`):

1. Work on a `feature/` branch — default name `feature/exploit-coverage-refresh-2026-10`.
2. The commit that changes `plugins/sui-ai/.claude-plugin/plugin.json` must also change at least
   one `plugins/sui-ai/agents/` file (the bump and the content it ships are never separated) and
   must carry the subject `feat(sui-move-auditor): <summary> (v2.3.0)`; conventional-commit
   format throughout, no attribution trailers.
3. Docs-only (`docs/**`), fixture-only (`tests/**`) and `CLAUDE.md`-only commits leave
   `plugin.json` unchanged. Suggested split: docs/sources; fixtures; plugin content + version
   bump (one commit); CLAUDE.md.
4. Open the PR to `main` with `gh pr create --base main --body-file docs/handoff/pr-body.md`;
   merge (never rebase) if the branch must integrate `main`.
