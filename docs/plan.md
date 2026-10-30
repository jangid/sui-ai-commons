---
status: planned
research_id: RS-001
last_updated: 2026-10-30
---

# Implementation Plan: Exploit-Coverage Refresh for `sui-move-auditor` (v2.3.0)

## Overview

Implement the six Approved specs in `docs/spec/` (index: `overview.md`): a durable
`docs/exploit-sources.md` with the rerun procedure; new and extended check text in the driver
`plugins/sui-ai/agents/sui-move-auditor.md` and three existing playbooks; a new companion
playbook `defi-perps-and-margin.md`; the strict `${CLAUDE_PLUGIN_ROOT}` companion-path rewrite
(operator decision 9); the five enumeration-site updates and the single version bump 2.2.0 →
2.3.0; and nine compiling vulnerable Move fixtures under `tests/fixtures/`. The plugin is text,
so every "check" is a bullet under an exact heading verified by `grep`; fixtures are the only
compiled artifact. Two bounded spikes (S-1 Switchboard `Aggregator` fields, S-2 fixture
framework-dependency variant) run first because the C9 table wording and all nine `Move.toml`
files depend on them. Plugin-content chunks (2–5) and fixture chunks (6–8) are independent of
each other and may run in parallel after Chunk 0; the version bump lands only in Chunk 5, the
last plugin-content chunk; Chunk 9 is the end-to-end verify.

Baseline facts recorded at planning (2026-10-30, commit `01a3f63`): `plugin.json` version is
`2.2.0`; `sui 1.81.1` is installed; no `tests/` directory exists; `grep -c CLAUDE_PLUGIN_ROOT $D`
= 3 (the `plugin_root_prefix_present` baseline); `no_bare_companion_mention` (release-wiring.md)
returns 27 lines corpus-wide: 25 in the driver (companion table lines 37–42; Phase 8B lines 719,
721, 724, 727; 15 in-text mentions at 53, 59, 136, 194, 381, 472, 496, 610, 614, 636, 642, 690,
737, 935, 943) plus `defi-lending-and-liquidation.md:40` and
`verification-and-false-positives.md:173` — Chunk 5 task 3 and Chunk 3 task 5 own those. Line
numbers drift as chunks land: re-run the grep to record, never trust the list.

## Conventions

- **Task types**: [implement] produces content (Markdown or Move) at the cited location,
  [spike] produces findings, [verify] validates behaviour against the spec's named checks.
- **Chunk headers**: `### Chunk N: <name>` per work unit; each chunk ≤ 6 tasks so a
  non-interactive subagent closes it in ≤ 25 tool calls.
- **Trace suffix**: every task ends `— traces to <spec>.md §<section or check id>`; check ids
  are the scenario names from each spec's `### Automated` list, AC-n is the n-th bullet of its
  `### Acceptance Criteria`.
- **Spike findings** are recorded inline in this plan as a `**Findings (S-n)**:` sub-bullet
  under the spike task when the task is ticked, and copied into the artifact the spec names
  (S-1 → the C9 provider table in `sui-native-pitfalls.md`; S-2 → the dependency-variant line
  of `tests/fixtures/README.md`).
- **Style constraints are fixed** (coverage-checks.md §Check contract schema): bold lead-in,
  ≤ 6 wrapped lines per driver bullet, ≤ 8 per playbook bullet, grep seeds in backticks, an
  invariant sentence containing "must", carve-outs introduced by "Not a finding when" or "Do not
  report", incident names only in parentheses.
- **Companion path rule** (operator decision 9): every companion-file mention written in this
  cycle uses `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md` on the same line.
- **Traceability**: at chunk close the implementer fills the `Implementation` cell (file →
  heading or fixture slug) and `Test` cell (check id(s) / fixture slug) of every
  `docs/requirements/traceability.md` row the chunk's tasks trace to; Chunk 9 verifies all 72
  live rows are filled. `Verified` stays for the verify stage.
- **Gates**: each chunk names the exact shell commands the chunk verifier runs from the repo
  root (`D=plugins/sui-ai/agents/sui-move-auditor.md`, `P=plugins/sui-ai/agents/sui-move-auditor`,
  `F=$P/defi-perps-and-margin.md`). "Both manifest parses" means
  `python3 -m json.tool plugins/sui-ai/.claude-plugin/plugin.json >/dev/null && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null`;
  it runs in every chunk because it is the repository's only lint. A gate written as `<cmd>` = N
  means the command's output (piped through `| wc -l | tr -d ' '` where a count is implied)
  equals N; a gate written as a bare command must exit 0.
- **Execution model and git**: the plan is executed chunk by chunk by a non-interactive
  subagent, in plan order unless the orchestrator opts into fan-out of independent chunks (the
  `Depends on` field is the machine-readable signal). After each chunk the ORCHESTRATOR commits
  that chunk's changes on `proceed` at a per-chunk gate; the subagent itself never commits,
  branches or opens a PR. Therefore every chunk STARTS on a clean tree whose HEAD already
  contains all previous chunks' commits. When the orchestrator fans out independent chunks,
  each fanned-out chunk runs in its OWN git worktree, so a whole-tree `git status --porcelain`
  check inside a chunk sees only that chunk's changes (the isolation gates below rely on this). Commit-shape checks in release-wiring.md
  (`bump_commit_subject_names_version`, `bump_and_content_same_commit`,
  `non_plugin_commits_do_not_bump`, `branch_prefix`, `pr_exists_to_main_with_rationale_table`)
  are satisfied by the orchestrator's commit split (suggested in release-wiring.md §Branch and
  PR); Chunk 9 produces the PR body text they need.
- **Isolation gates are this-chunk's-own-changes checks**: at chunk entry the subagent records
  `BASE=$(git rev-parse HEAD)` and reports it in its return so the chunk verifier reuses the same
  value. A chunk's "nothing else changed" gate is `git diff --name-only "$BASE" -- <paths> | wc -l`
  = 0 together with `git status --porcelain -- <paths> | wc -l` = 0 (catches untracked files)
  over the paths the chunk must NOT touch. A gate never asserts that files changed by an EARLIER
  chunk are unchanged relative to `main`. The two places a diff against the branch point is
  genuinely wanted (`## Self-liquidation & self-match` in the lending file; `marketplace.json`,
  which no chunk may ever change) say `git diff main -- <file>` explicitly and are restricted to
  the expected hunks.
- **Fixture build environment (verified 2026-10-30 in the executing sandbox)**: `sui move build`
  works ONLY with `export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"` set (the home-directory
  `~/.sui` and `~/.move` paths are not writable there), with stdin redirected from `/dev/null`,
  and with the framework declared explicitly in `Move.toml` as
  `Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "bf4073918ed33cfa0b09c500658fa116a774bcfd" }`
  (that commit is cached locally; network access to `github.com` is required on the first build
  of any other rev). Every fixture build gate line (Chunks 0, 6, 7, 8, 9) therefore carries the
  two exports and `</dev/null`; implementers run builds the same way. After the first build
  `Move.lock` pins the dependency and builds are offline.

## Chunks

### Chunk 0: Spikes S-1 and S-2
**Goal**: Both `[high-uncertainty]` sections are resolved before any check text or fixture is
written; the fixture dependency variant is a single recorded repository-wide decision.
**Depends on**: None.
**Tasks**:
1. [spike] **S-1 — Switchboard On-Demand `Aggregator` authority model.** Budget: ≤ 5 tool calls,
   2 sources (`on_demand/sources/schemas/aggregator.move` and the `actions/aggregator_*` modules
   in `github.com/switchboard-xyz/sui`, raw fetch; fallback source: Switchboard Sui docs page).
   Record: the readable field names for feed authority and queue, the setter guards
   (`set_authority`, `set_configs` or their actual names), and the `CurrentResult` accessor
   names. Outcome A (fields + guarded setters exist): the C9 Switchboard row keeps "pin
   aggregator ID + queue ID + authority". Outcome B (no readable authority): adopt the fallback
   wording "pin aggregator ID + queue ID + consumer-side staleness/variance" and note it. Record
   the outcome as `**Findings (S-1)**` under this task — traces to coverage-checks.md §C9
   CHK-C9-1 [high-uncertainty] Spike S-1; AC-14
2. [spike] **S-2 — fixture framework-dependency variant under Sui CLI 1.81.1.** Budget: ≤ 4 tool
   calls, 1 build. The explicit pinned variant is ALREADY KNOWN to build (§Conventions → Fixture
   build environment: `rev = "bf4073918ed33cfa0b09c500658fa116a774bcfd"` under the two exports),
   so S-2's only remaining question is whether the implicit-system-dependency variant also
   builds under the same exports — then pick one. Create
   `tests/fixtures/c11-governance-capture/Move.toml` per the fixtures.md `Move.toml` contract
   with **no** `[dependencies]` table (implicit variant), a stub `sources/governance.move` module
   (`module c11_governance_capture::governance;` with one `public struct` so the package is
   non-empty), run `export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome"; sui move build </dev/null`
   from that directory. Zero warnings and exit 0 → variant = implicit (record "implicit framework
   dependency; `Move.lock` committed"). Any warning mentioning implicit dependencies, or a
   failure → variant = the explicit git dependency line quoted in §Conventions (pinned to the
   cached commit `bf4073918ed33cfa0b09c500658fa116a774bcfd`; record it) and rebuild. Write the result as the
   dependency-variant sentence in a minimal `tests/fixtures/README.md` (title line + the
   sentence; the table is added in Chunk 8) and as `**Findings (S-2)**` under this task
   — traces to fixtures.md §`Move.toml` contract [high-uncertainty] Spike S-2; AC-2
3. [verify] Confirm neither replan trigger fired (S-1 produced one of the two named outcomes;
   S-2 produced a zero-warning build under exactly one variant), the stub builds clean, and
   `Move.lock` was generated — traces to fixtures.md §each_fixture_builds_clean;
   overview.md §high_uncertainty_sections_have_spike_and_fallback
**Entry criteria**: None (first chunk).
**Exit criteria**: `**Findings (S-1)**` and `**Findings (S-2)**` recorded in this plan;
`tests/fixtures/c11-governance-capture/{Move.toml,Move.lock,sources/governance.move}` and
`tests/fixtures/README.md` (variant sentence) exist; stub build is clean.
**Gates**: `rc=0; out=$(cd tests/fixtures/c11-governance-capture && export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome" && sui move build 2>&1 </dev/null) || rc=1; printf '%s\n' "$out"; grep -qiE '^(warning|error)' <<<"$out" && rc=1; exit $rc` exits 0 (the build's own exit status is preserved, as in fixtures.md `each_fixture_builds_clean`);
`test -f tests/fixtures/c11-governance-capture/Move.lock`; `grep -ciE 'implicit|explicit' tests/fixtures/README.md` ≥ 1;
`python3 -m json.tool plugins/sui-ai/.claude-plugin/plugin.json >/dev/null && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null`.

### Chunk 1: `docs/exploit-sources.md`
**Goal**: The durable source list and rerun procedure exist and pass every exploit-sources.md
automated check; nothing under `plugins/` changes.
**Depends on**: None (may run in parallel with Chunk 0).
**Tasks**:
1. [implement] Create `docs/exploit-sources.md` with the frontmatter contract (`cutoff:
   2026-10-30`, `produced_by: RS-001`, `first_run_window: "[2025-10-30, 2026-10-30]"`,
   `last_updated`) and the first three of the SEVEN fixed-order sections — `# Exploit Sources`,
   `## Current cutoff`, `## Primary set`, `## Sources (ranked)`, `## Retry list`,
   `## Rerun procedure`, `## Change log` (tasks 2–4 add the remaining four in exactly that order;
   the Chunk 1 order gate checks the whole sequence) — namely: `# Exploit Sources`;
   `## Current cutoff` containing the literal `date > cutoff_prev` and the inclusive first-run
   window worded as "from 2025-10-30 through 2026-10-30, inclusive" — the bracketed literal
   `[2025-10-30, 2026-10-30]` appears ONLY in the frontmatter `first_run_window` value, never in
   the body (see ## Open Questions, spec lines 39 vs 205); `## Primary set` naming DeFiLlama
   hacks API, rekt.news, SlowMist Hacked and the budget-constrained-rerun rule — traces to exploit-sources.md §Frontmatter contract, §Section
   order; sources_file_exists_outside_plugins, frontmatter_has_cutoff_and_spike,
   strict_after_rule_stated, primary_set_names_three_sources_with_filter_field; AC-1
2. [implement] Add `## Sources (ranked)` with eleven `### <rank>. <name>` subsections (RS-001
   table (a) order, read from `docs/research/RS-001-exploit-coverage-refresh/findings.md` and
   `notes.md`), each carrying the nine labelled field lines in the fixed order, every one written
   as `- **<Label>:** <value>` with the label verbatim (`URL(s)`, `Covers`, `Fetch method`,
   `Cadence`, `Rank`, `Verification status`, `Last checked`, `Date filter field`, `Notes`) and
   `n/a`, never blank, when a field does not apply; `Last checked`
   is `2026-10-30` for #1–#6 and #8, `never attempted` for #7 and #9–#11 (re-check `notes.md`
   only for #9 and reclassify if a request against its recorded URL was issued); `Date filter
   field` non-`n/a` only for the primary three — traces to exploit-sources.md §Per-source field
   block, §Initial content; eleven_sources_present_in_rank_order,
   every_source_has_full_field_block, last_checked_is_date_or_never; AC-2
3. [implement] Add `## Retry list` directly after `## Sources (ranked)` (columns `Source | Reason it failed | What to try next |
   Since (run)`, rows for #7, #8, #9, #10, #11 — one row for every source whose
   `Verification status` is not `verified this run`, the `Source` cell repeating the
   `### <rank>. <name>` name verbatim — with the reasons and next queries fixed in the
   spec) and `## Change log` as the LAST section of the file, with one row for the 2026-10-30 /
   RS-001 run (task 4 inserts `## Rerun procedure` between the two) — traces to
   exploit-sources.md §Retry list contract; retry_list_covers_unverified_sources; AC-3
4. [implement] Add `## Rerun procedure` between `## Retry list` and `## Change log`, as a
   ten-step ordered list with the exact URLs, filter
   fields, year-rollover path, `$1M`/`$10M` thresholds, `C1–C25` classification, the
   untrusted-data rule, the Retry-list pass, and step 10 carrying the spike-contract sub-bullets
   (`RS-00N`, immutability of earlier spikes, `docs/research/index.md` row, `## Repeatability`,
   cutoff = `UTC day` the catalog is closed) — traces to exploit-sources.md §Rerun procedure
   contract, §Rerun spike contract; procedure_has_required_steps_in_order; AC-4, AC-5
5. [verify] Run the ten exploit-sources.md automated checks as shell commands; render-check
   every table (`grep -c '^|'` per table equals header+separator+rows); confirm this chunk
   touched nothing under `plugins/` and added no `scripts/`, cron or workflow file (BASE diff and
   porcelain over `plugins/ .github/ scripts/`) — traces to
   exploit-sources.md §Automated (all ten), no_automation_shipped; AC-6, AC-7
**Entry criteria**: RS-001 `findings.md` and `notes.md` readable.
**Exit criteria**: all ten automated checks pass; `plugins/` untouched by this chunk.
**Gates**: `test -f docs/exploit-sources.md && ! find plugins -name '*exploit-sources*' | grep -q .`;
`grep -cE '^cutoff: [0-9]{4}-[0-9]{2}-[0-9]{2}$' docs/exploit-sources.md` = 1; `grep -cE '^produced_by: RS-[0-9]{3}$' docs/exploit-sources.md` = 1;
`grep -cE '^### [0-9]+\. ' docs/exploit-sources.md` = 11; `grep -oE '^### [0-9]+' docs/exploit-sources.md | tr -d '# ' | paste -sd, -` = `1,2,3,4,5,6,7,8,9,10,11`;
`grep -cE '^- \*\*Last checked:\*\*' docs/exploit-sources.md` = 11 and `grep -E '^- \*\*Last checked:\*\*' docs/exploit-sources.md | grep -vcE ':\*\* (`?[0-9]{4}-[0-9]{2}-[0-9]{2}`?|never attempted)$'` = 0 (last_checked_is_date_or_never, anchored to field lines so the procedure steps 9–10 prose that mentions "Last checked" does not count);
`grep -F 'date > cutoff_prev' docs/exploit-sources.md` matches; `sed -n '2,/^---$/p' docs/exploit-sources.md | grep -cF '[2025-10-30, 2026-10-30]'` = 1 (frontmatter carries the literal once) and `sed '1,/^---$/d' docs/exploit-sources.md | grep -cF '[2025-10-30, 2026-10-30]'` = 0 (body never repeats it; `sed '1,/^---$/d'` strips through the second `---`) and `sed -n '/^## Current cutoff/,/^## Primary set/p' docs/exploit-sources.md | grep -cF 'from 2025-10-30 through 2026-10-30, inclusive'` = 1 (strict_after_rule_stated);
`grep '^#\{1,2\} ' docs/exploit-sources.md | paste -sd'|' -` = `# Exploit Sources|## Current cutoff|## Primary set|## Sources (ranked)|## Retry list|## Rerun procedure|## Change log` (seven-section order; also catches a stray `#`/`##` heading);
for each phrase in `cutoff_prev untrusted api.llama.fi/hacks rekt.news/leaderboard hacked.slowmist.io 'past/<YYYY>/README.md' forums.sui.io 'Notorious Bug Digest' '$1M' '$10M' 'C1–C25' 'Retry list' RS-00N docs/research/index.md Repeatability 'UTC day'`: `sed -n '/^## Rerun procedure/,/^## Change log/p' docs/exploit-sources.md | grep -nF -- "<phrase>"` matches with ascending first-hit line numbers;
`for n in $(seq 1 11); do blk=$(awk -v n="$n" 'BEGIN{h="^### " n "\\. "} $0 ~ h {p=1; print; next} p && /^### [0-9]+\. |^## /{p=0} p' docs/exploit-sources.md); for lbl in 'URL(s)' 'Covers' 'Fetch method' 'Cadence' 'Rank' 'Verification status' 'Last checked' 'Date filter field' 'Notes'; do [ "$(grep -cF -- "- **$lbl:**" <<<"$blk")" = 1 ] || { echo "$n $lbl"; exit 1; }; done; done` (every_source_has_full_field_block);
`sed -n '/^## Primary set/,/^## Sources/p' docs/exploit-sources.md | grep -ciE 'defillama|rekt\.news|slowmist'` ≥ 3 with each of the three names matching at least once, and `for n in 1 2 3; do awk -v n="$n" 'BEGIN{h="^### " n "\\. "} $0 ~ h {p=1; print; next} p && /^### [0-9]+\. |^## /{p=0} p' docs/exploit-sources.md | grep -F -- '- **Date filter field:**' | grep -qv 'n/a' || { echo "$n"; exit 1; }; done` and the same loop for `n in 4 5 6 7 8 9 10 11` with `grep -q 'n/a'` (primary_set_names_three_sources_with_filter_field; #1–#3 are the primary three);
`for n in $(seq 1 11); do blk=$(awk -v n="$n" 'BEGIN{h="^### " n "\\. "} $0 ~ h {p=1; print; next} p && /^### [0-9]+\. |^## /{p=0} p' docs/exploit-sources.md); grep -qE -- '- \*\*Verification status:\*\* `?verified this run' <<<"$blk" && continue; name=$(grep -m1 '^### ' <<<"$blk" | sed -E 's/^### [0-9]+\. //'); sed -n '/^## Retry list/,/^## Change log/p' docs/exploit-sources.md | grep -qF -- "$name" || { echo "$n"; exit 1; }; done` (retry_list_covers_unverified_sources);
`git diff --name-only "$BASE" -- plugins/ .github/ scripts/ | wc -l` = 0 and `git status --porcelain -- plugins/ .github/ scripts/ | wc -l` = 0 (this chunk's own changes only); both manifest parses.

### Chunk 2: New playbook `defi-perps-and-margin.md`
**Goal**: The perps playbook exists at the fixed path with the opener, preamble, six fixed
headings, PB-1..5 and the known-good section, and passes every file-local perps-playbook.md
check.
**Depends on**: Chunk 0 (ordering only; no content dependency — may run in parallel with Chunks 3 and 6–8).
**Tasks**:
1. [implement] Create `$F` with title `# Playbook — Perpetuals, Funding & Margin`, the "Load
   when …" opener containing the dual-load sentence with the full path to
   `defi-lending-and-liquidation.md`, the one-line preamble containing "max Medium" within the
   first 10 lines (its pointer to the verification playbook written as
   `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/verification-and-false-positives.md` on that
   line, never the bare filename), and the six `## ` headings of §Section skeleton in order (exact strings) —
   traces to perps-playbook.md §File and load trigger, §Section skeleton;
   playbook_file_exists_in_companion_dir, load_when_opener_states_dual_load,
   six_fixed_headings_present_in_order, preamble_states_cap, known_good_section_present; AC-1
2. [implement] Write PB-1 (`## Funding settlement ordering`: settle-first invariant, "before",
   `Clock`, cross-refs with full paths to the lending `## Interest & accrual ordering` and
   staking `## Checkpoint & accumulator ordering (the core bugs)` headings, lazy-settle
   carve-out) and PB-2 (`## Funding-rate updates: permissioned or bounded`: writer enumeration
   with grep seeds, "funding-manipulation window", bounded-`poke` carve-out) — traces to
   perps-playbook.md §Check contracts PB-1, PB-2; pb1_settle_first, pb2_window_named; AC-3
3. [implement] Write PB-3 (`## Self-trade and mark-price manipulation on thin books`: "owner
   addresses, not account IDs", smoothed/bounded mark price with "deviation", full-path
   cross-refs to the lending self-match bullet and the AMM `## Order books & matching loops`,
   oracle-only-mark carve-out) and PB-4 (`## Risk-parameter changes and open positions`:
   setter enumeration, "re-check" and "transition"/"grace", cross-refs to **LTV strictly below
   the liquidation threshold, with a gap** and **Admin-origin latent user DoS**, bounded
   tighten-only carve-out) — traces to perps-playbook.md §Check contracts PB-3, PB-4;
   pb3_owner_not_account, pb4_transition; AC-3
4. [implement] Write PB-5 (`## Fees, funding and collateral deltas as signed-value sinks`:
   sink list — taker/maker fee, integrator/builder fee codes, funding payments, realised PnL,
   collateral deltas — and a one-line pointer to the driver's 5.3a **Raw-bits stored,
   signed-read** check, no restatement of the C3 contract) and the
   `## Known-good patterns — DO NOT report these as bugs` section with the four fixed entries
   (lazy settle on read, trusted keeper setter → blast radius, bounded mark≠index premium,
   liquidation-profitability sanity gate) — traces to perps-playbook.md §Check contracts PB-5,
   §Known-good patterns section; pb5_points_to_driver, known_good_section_present; AC-3, AC-4
5. [verify] Run the file-local perps-playbook.md checks and the decision-9 grep over `$F`
   (every companion filename in `$F` carries the full path on the same line); count bullet
   lengths ≤ 8 lines; confirm this chunk did not touch `$P/defi-lending-and-liquidation.md`
   (`git diff --name-only "$BASE" -- $P/defi-lending-and-liquidation.md` is empty) — traces to perps-playbook.md §Automated (file-local checks),
   no_bare_companion_mention_perps, lending_margin_content_untouched; AC-5; coverage-checks.md
   §style_lengths
**Entry criteria**: Chunk 0 closed.
**Exit criteria**: all file-local checks pass; the companion-table/8B checks of
perps-playbook.md remain open for Chunk 5.
**Gates**: `test -f $F`; `head -6 $F | grep -q 'Load when' && head -6 $F | grep -qF '${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md'`;
`grep '^## ' $F` prints exactly, in order: `## Funding settlement ordering`, `## Funding-rate updates: permissioned or bounded`, `## Self-trade and mark-price manipulation on thin books`, `## Risk-parameter changes and open positions`, `## Fees, funding and collateral deltas as signed-value sinks`, `## Known-good patterns — DO NOT report these as bugs`; `grep -cF '## Fees, funding and collateral deltas as signed-value sinks' $F` = 1 (headings_exist_verbatim, perps part);
`head -10 $F | grep -q 'max Medium'`; per-section greps (`awk '/^## <heading>/,/^## <next heading>/' $F`): section 1 `before|first` and `Clock`; section 2 `window` and `permission|bounded`; section 3 `owner address` and `mark` and `smooth|deviation`; section 4 `re-check|recheck` and `transition|grace`; section 5 `5\.3a|Raw-bits` and `fee` and `funding` and `collateral`;
`grep -nE '(^|[^/])(verification-and-false-positives|defi-shares-and-vaults|defi-amm-and-slippage|defi-lending-and-liquidation|defi-staking-and-rewards|sui-native-pitfalls|defi-perps-and-margin)\.md' $F | grep -v CLAUDE_PLUGIN_ROOT | wc -l` = 0;
`git diff --name-only "$BASE" -- $P/defi-lending-and-liquidation.md | wc -l` = 0 and `git status --porcelain -- $P/defi-lending-and-liquidation.md | wc -l` = 0 (this chunk edits only `$F`; Chunk 3's lending edits may already be in HEAD); both manifest parses.

### Chunk 3: Existing-playbook edits (C7, C8, C9, C12, catalog rows)
**Goal**: The lending playbook carries C7-1..3 and C8-1..3; `sui-native-pitfalls.md` carries
the new oracle-integrations section (with S-1 findings) and the three C12 bullets;
`verification-and-false-positives.md` carries the four catalog rows; the two bare companion
mentions in playbooks are rewritten.
**Depends on**: Chunk 0 (S-1 findings feed the Switchboard row).
**Tasks**:
1. [implement] In `$P/defi-lending-and-liquidation.md` under `## Market creation &
   configuration validation`, add the bolded sub-block **Collateral listing quality** with
   CHK-C7-1 (caps vs liquidity depth; the three fixed outcomes incl. "depth unknown → every
   capped collateral reported as `needs_review` … could not be assessed", isolated-collateral
   carve-out) and CHK-C7-2 (same-asset borrow/re-supply bound, cross-ref to the driver's
   **Per-call vs. per-transaction limits**) — traces to coverage-checks.md §C7 CHK-C7-1,
   CHK-C7-2; c7_in_market_creation, c7_depth_unknown_path; AC-4
2. [implement] In the same file under `## Oracle staleness & price representability`, after
   **No unpriced-asset $1 assumption**, add CHK-C7-3 (single-fill price rejected; seize-leg spot
   carve-out) and CHK-C8-1..3 (ratio feed composed with base feed; "sanity band"/"deviation" on
   feed swaps with the trust-model qualifier; coupled cap parameters updated "atomically"/
   "together", cross-ref **Config updates that clobber runtime state**). Do not touch
   `## Self-liquidation & self-match` — traces to coverage-checks.md §C7 CHK-C7-3, §C8
   CHK-C8-1..3; c7_c8_in_oracle_staleness; AC-4, AC-5; perps-playbook.md
   §lending_margin_content_untouched
3. [implement] In `$P/sui-native-pitfalls.md`, insert the new section `## Oracle integrations
   (Pyth / Switchboard / custom feeds)` directly after `## Cross-chain / bridge / ZK` (before
   `## PTB deliverability & production reachability`) with the "Applies when … max Medium"
   preamble, CHK-C9-1 with the three-row provider table (Pyth row names
   `get_price_identifier`, originating package, `get_price_no_older_than`, confidence, and **no**
   authority pin; Switchboard row per S-1 outcome with the recorded field/setter names; custom
   row), and CHK-C9-2..4 bullets (min count / per-update move bound with the `min_sample_size`
   carve-out; round trip within one staleness window; keeper-report plausibility bound
   cross-referencing **Signatures validated against live mutable policy**) — traces to
   coverage-checks.md §C9 CHK-C9-1..4; c9_section_and_table; AC-6 (section part), AC-14
4. [implement] In `$P/sui-native-pitfalls.md` under `## Cross-chain / bridge / ZK`, after
   **Fake bridge package object**, add CHK-C12-1 (verifier set size/threshold ≥ 2; 1-of-1 "no
   lower than High" after the two-gate check "regardless of operator reputation"; Medium
   pattern-only), CHK-C12-2 (uniqueness tied to full message hash/nullifier, cross-ref the
   existing **Nonce replay** bullet) and CHK-C12-3 (refund ≤ deposited; failed callbacks inert,
   cross-ref **Hard platform limits**) — traces to coverage-checks.md §C12 CHK-C12-1..3;
   c12_three_bullets; AC-8
5. [implement] In `$P/verification-and-false-positives.md`, append four rows to the table under
   `## Move-specific false-positive catalog ("looks vulnerable, is safe")` (CAT-1 fee-on-transfer
   / `sync`/`skim`, CAT-2 token-approval abuse, CAT-3 EVM proxy / delegatecall, CAT-4 off-chain
   TSS crypto; three columns; `CAT-n` ids not written), keep the Reentrancy row; and rewrite the
   two bare companion mentions (`defi-lending-and-liquidation.md:40`,
   `verification-and-false-positives.md:173` at baseline) to the full-path form — traces to
   coverage-checks.md §n/a classes CAT-1..4; catalog_rows_added; AC-10; release-wiring.md
   §Companion wiring, no_bare_companion_mention (playbook share)
6. [verify] Run the chunk's greps; check each new bullet ≤ 8 wrapped lines, has a bold lead-in
   that is not a protocol name, states or inherits the Medium cap, names its enumeration set and
   its absence report — traces to coverage-checks.md §Cross-cutting rules; no_incident_as_subject,
   style_lengths; AC-11, AC-12
**Entry criteria**: Chunk 0 closed (S-1 findings recorded).
**Exit criteria**: all greps below pass; `## Self-liquidation & self-match` has no deletions.
**Gates**: `for h in '## Market creation & configuration validation' '## Oracle staleness & price representability' '## Self-liquidation & self-match'; do [ "$(grep -cF -- "$h" $P/defi-lending-and-liquidation.md)" = 1 ] || { echo "$h"; exit 1; }; done`; `grep -cF '## Cross-chain / bridge / ZK' $P/sui-native-pitfalls.md` = 1; `grep -cF '## Move-specific false-positive catalog ("looks vulnerable, is safe")' $P/verification-and-false-positives.md` = 1 (headings_exist_verbatim, playbook part);
`awk '/^## Market creation & configuration validation/,/^## Interest/' $P/defi-lending-and-liquidation.md | grep -q 'Collateral listing quality'` and the same block contains `needs_review`, `re-supply|resupply`, `could not be assessed|depth unknown`;
`awk '/^## Oracle staleness & price representability/,/^## Solvency/' $P/defi-lending-and-liquidation.md` contains `single fill`, `ratio`, `sanity band|deviation`, `atomically|together`;
`grep -cF '## Oracle integrations (Pyth / Switchboard / custom feeds)' $P/sui-native-pitfalls.md` = 1; that section (`awk '/^## Oracle integrations/,/^## PTB deliverability/'`) contains `PriceInfoObject`, `Aggregator`, `get_price_identifier`, `max Medium`; the Pyth row (`awk '/^## Oracle integrations/,/^## PTB deliverability/' $P/sui-native-pitfalls.md | grep '^|' | grep -c PriceInfoObject` = 1) is read MANUALLY by the verifier to confirm it does not instruct pinning an authority — the negative grep `pin.*authority` is not a gate because the row may legitimately say "no authority pin";
`awk '/^## Cross-chain \/ bridge \/ ZK/,/^## Oracle integrations/' $P/sui-native-pitfalls.md` contains `threshold` and `High`, `message hash|full message|nullifier`, `refund`;
`awk '/^## Move-specific false-positive catalog/,/^## Move-aware trust model/' $P/verification-and-false-positives.md` matches `[Ff]ee-on-transfer`, `approval`, `proxy|delegatecall`, `TSS|off-chain crypto`, `Reentrancy`;
`grep -nE '(^|[^/])(verification-and-false-positives|defi-shares-and-vaults|defi-amm-and-slippage|defi-lending-and-liquidation|defi-staking-and-rewards|sui-native-pitfalls|defi-perps-and-margin)\.md' $P/*.md | grep -v CLAUDE_PLUGIN_ROOT | wc -l` = 0;
`git show main:$P/defi-lending-and-liquidation.md | sed -n '/^## Self-liquidation & self-match/,/^## Known-good/p' > "$TMPDIR/selfliq_main.txt"; sed -n '/^## Self-liquidation & self-match/,/^## Known-good/p' $P/defi-lending-and-liquidation.md > "$TMPDIR/selfliq_tree.txt"; diff "$TMPDIR/selfliq_main.txt" "$TMPDIR/selfliq_tree.txt" | grep -c '^<'` = 0 (lending_margin_content_untouched: the section is compared directly against the branch point, from its heading up to and including the `## Known-good patterns` heading line, so hunk boundaries are irrelevant and no line of the original may disappear or change; where process substitution is available the one-liner `diff <(git show main:$P/defi-lending-and-liquidation.md | sed -n '/^## Self-liquidation & self-match/,/^## Known-good/p') <(sed -n '/^## Self-liquidation & self-match/,/^## Known-good/p' $P/defi-lending-and-liquidation.md) | grep -c '^<'` = 0 is equivalent); `git diff --name-only "$BASE" | grep -v "^$P/" | grep -v '^docs/' | wc -l` = 0 and `git status --porcelain | awk '{print $2}' | grep -v "^$P/" | grep -v '^docs/' | wc -l` = 0 (this chunk edits only playbooks; whole-tree porcelain is valid because a fanned-out chunk runs in its own worktree); both manifest parses.

### Chunk 4: Driver check content (C19, C3, C11, C6, C7-4, C9 load)
**Goal**: Every driver heading in coverage-checks.md §Class inventory exists verbatim with its
new bullets; the 6.8 rename is applied; the old heading is gone.
**Depends on**: Chunk 0 (ordering); edits only `$D`, so it may run in parallel with Chunks 2, 3 and 6–8 but must close before Chunk 5.
**Tasks**:
1. [implement] Phase 1: add numbered step `10.` after step 9 (fork-ancestry sweep) and before
   `### 1.1` — record the pinned framework/protocol version from `Move.toml`/`Move.lock`, the
   deployment chain (flag non-Sui-mainnet Move VMs), a published-advisory check, ending with
   "Advisory context only — this step never produces a finding by itself." — traces to
   coverage-checks.md §C19 CHK-C19-1; c19_step_10; AC-9
2. [implement] 5.3a: add one to three bullets after the existing greps, the first with lead-in
   **Raw-bits stored, signed-read (domain reinterpretation).** (CHK-C3-1: enumerate
   cross-domain numeric fields on a path to a value sink, grep seeds, "must" invariant, absence,
   `likely` on traced path, Medium cap, carve-outs), followed directly by the write-boundary
   validation bullet (CHK-C3-2, "constructor") and the same-domain caps bullet (CHK-C3-3,
   "consuming domain", two's-complement evidence gate for High) — traces to coverage-checks.md
   §C3 CHK-C3-1..3; c3_bullets_in_5_3a; AC-2
3. [implement] 6.8: rename the heading to `### 6.8 Governance, Voting & Weight Safety`, keep the
   five existing checkboxes, prepend the fixed trigger line (grep
   `propose|vote|cast|quorum|execute_proposal|timelock`, "record each outcome individually"),
   add five `- [ ]` items for CHK-C11-1..5 (snapshot before proposal; quorum relative to voting
   supply and proposer threshold > 0; execution delay + veto/guardian; allow-list payload with
   the three Move shapes of "arbitrary payload"; vote-token lock / re-vote, with the
   snapshot-makes-it-moot carve-out) — traces to coverage-checks.md §C11 CHK-C11-0..5;
   headings_exist_verbatim (6.8 part), c11_trigger_and_five_items; AC-1, AC-7
4. [implement] 6.14: add three `- [ ]` items directly after **Stale-package attack surface** —
   CHK-C6-1 (two live writers of one accounting field, `[ZD-EXT-UNVERIFIED]` when prior source
   is unavailable), CHK-C6-2 (`make_immutable|burn.*UpgradeCap|...` seeds; "no lower than High"
   after the two-gate check, Medium pattern-only, pure-library carve-out), CHK-C6-3 (legacy
   entry points reachable via routers/aggregators) — traces to coverage-checks.md §C6
   CHK-C6-1..3; c6_three_items_in_6_14, c6_floor_stated; AC-3
5. [implement] 7.2: add the CHK-C7-4 bullet **Permissionless NAV/AUM/price refresh** (grep
   seeds `update_nav|update_aum|refresh_price|sync_price|poke`, "TWAP or deviation gate",
   capability-holder carve-out) and directly after it the CHK-C9 bullet **Consumed-feed
   authority and plausibility** — an explicit "load
   `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/sui-native-pitfalls.md` and run its
   `## Oracle integrations (Pyth / Switchboard / custom feeds)` section" instruction. The C9
   bullet must not contain a `|` character after the path on that line (it would make
   `sui_native_load_condition_mentions_oracle` return two lines) — traces to coverage-checks.md
   §C7 CHK-C7-4, §C9 driver bullet; c7_4_refresh_in_7_2, c9_driver_load_instruction; AC-4
   (refresh part), AC-6 (7.2 part); release-wiring.md §Placement of checks; AC-3 (CHK-C7-4 part)
6. [verify] Run the chunk's greps; count each new driver bullet ≤ 6 wrapped lines; confirm no
   new bold lead-in begins with a protocol name; confirm `grep -c CLAUDE_PLUGIN_ROOT $D` did not
   decrease — traces to coverage-checks.md §headings_exist_verbatim (driver part),
   no_incident_as_subject, style_lengths; AC-11, AC-12; release-wiring.md
   §plugin_root_prefix_present
**Entry criteria**: Chunk 0 closed; Chunk 5 not started (same file).
**Exit criteria**: all gates pass; `$D` is the only file changed by this chunk.
**Gates**: `for h in '### 5.3a High-signal correctness greps (cheap, high severity)' '### 6.14 Package Upgrade Safety' '### 7.2 Oracle & Price Manipulation' '## PHASE 1 — CONTEXT GATHERING' '### 6.8 Governance, Voting & Weight Safety'; do [ "$(grep -cF -- "$h" $D)" = 1 ] || { echo "$h"; exit 1; }; done` and `grep -cF '### 6.8 Weight & Governance Safety' $D` = 0 (headings_exist_verbatim, driver part);
`awk '/^### 5\.3a/,/^### 5\.4/' $D | grep -E '^- \*\*[^*]*[Ss]igned' | wc -l` ≥ 1 and that block contains `write boundary|constructor` and `same domain|consuming domain`; `new=$(( $(awk '/^### 5\.3a/,/^### 5\.4/' $D | grep -c '^- ') - $(git show "$BASE":$D | awk '/^### 5\.3a/,/^### 5\.4/' | grep -c '^- ') )); [ "$new" -ge 1 ] && [ "$new" -le 3 ]` (c3_bullets_in_5_3a upper bound: one to three new bullets);
`awk '/^### 6\.14/,/^### 6\.15/' $D` has `- [ ]` lines matching `writer`, `make_immutable|UpgradeCap` (that line also contains `High`), `router|aggregator|legacy entry`;
`awk '/^### 6\.8/,/^### 6\.9/' $D` contains `record each outcome|individually` and `- [ ]` lines matching `snapshot`, `quorum`, `(delay|timelock).*(veto|guardian)|(veto|guardian).*(delay|timelock)`, `allow-list|allowlist`, `lock|re-vote`;
`awk '/^### 7\.2/,/^### 7\.3/' $D | grep -E 'refresh' | grep -qE 'TWAP|deviation'`; `awk '/^### 7\.2/,/^### 7\.3/' $D | grep -F '${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/sui-native-pitfalls.md' | grep -qi 'load'`; `awk '/^### 7\.2/,/^### 7\.3/' $D | grep 'sui-native-pitfalls\.md' | grep -vc CLAUDE_PLUGIN_ROOT` = 0;
`s=$(awk '/^## PHASE 1 /,/^### 1\.1/' $D | awk '/^10\. /{p=1} /^### 1\.1/{p=0} p'); grep -q 'framework' <<<"$s" && grep -qi 'advisor' <<<"$s" && grep -qE 'never produces a finding|Advisory context only' <<<"$s"` (c19_step_10: the `10.` line and its wrapped continuation lines up to `### 1.1`, piped through the three greps);
`grep -iE 'sui-native-pitfalls\.md.*\|.*oracle' $D | wc -l` = 0 (sui_native_load_condition_mentions_oracle, Chunk 4 form: the companion-table row is not amended until Chunk 5, so any hit here is a `|` leaking into the 7.2 C9 bullet — the Chunk 5 gate then requires exactly 1);
`grep -c CLAUDE_PLUGIN_ROOT $D` ≥ 3 (baseline at `01a3f63`); `git diff --name-only "$BASE" | grep -v '^plugins/sui-ai/agents/sui-move-auditor.md$' | grep -v '^docs/' | wc -l` = 0 and `git status --porcelain | awk '{print $2}' | grep -v '^plugins/sui-ai/agents/sui-move-auditor.md$' | grep -v '^docs/' | wc -l` = 0 (this chunk's own changes: `$D` only); both manifest parses.

### Chunk 5: Driver wiring, enumeration sync, CLAUDE.md, version bump 2.3.0
**Goal**: The companion table and Phase 8B are in full-path form with the perps row and the
oracle load condition; all five enumeration sites agree; `no_bare_companion_mention` is clean
across the corpus; `plugin.json` is `2.3.0`. This is the LAST plugin-content chunk.
**Depends on**: Chunk 2, Chunk 3, Chunk 4.
**Tasks**:
1. [implement] COMPANION REFERENCES table in `$D`: rewrite all six existing first-column cells
   to `` `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md` ``; insert the perps row
   (exact text from perps-playbook.md §File and load trigger) after the lending row; append the
   lending row's suffix "— margin targets also load
   `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md`"; add "oracle /
   third-party price-object consumption" to the `sui-native-pitfalls.md` row's load condition —
   traces to perps-playbook.md §File and load trigger; companion_table_row_present; AC-2;
   release-wiring.md §Companion wiring, §Enumeration sites #2; companion_table_all_full_path,
   sui_native_load_condition_mentions_oracle; AC-2, AC-3; coverage-checks.md AC-6 (table part)
2. [implement] Phase 8B in `$D`: rewrite the four archetype rows to full-path form; extend the
   **Lending / margin** row with "and, for margin or leveraged targets,
   `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md`" plus the perps
   parenthetical (funding settlement order, funding-rate bounds, self-trade on thin books,
   risk-parameter transitions, signed-value sinks) — traces to perps-playbook.md §File and load
   trigger (Phase 8B row); phase_8b_row_names_both; AC-2; release-wiring.md §Enumeration sites #3
3. [implement] Rewrite every remaining in-text companion mention in `$D` (baseline hits ~53, 59,
   136, 194, 381, 472, 496, 610, 614, 636, 642, 690, 737, 935, 943 — re-run the grep, do not
   trust the list) to carry the full path on the same line; where a line would exceed the
   file's wrap width, re-wrap so name and path stay on one line — traces to release-wiring.md
   §Companion wiring; no_bare_companion_mention, no_relative_or_repo_paths_in_plugin; AC-2;
   perps-playbook.md §no_bare_companion_mention_perps; AC-5
4. [implement] Enumeration sites #1 and #4 in `$D`: frontmatter `description` →
   `archetype playbooks (vaults/AMM/lending/perps-margin/staking)`; Appendix C methodology item
   8 → `Protocol-archetype playbook (vault / AMM / lending / perps-margin / staking, as
   applicable)` — traces to release-wiring.md §Enumeration sites #1, #4;
   five_enumeration_sites_updated; AC-6
5. [implement] `CLAUDE.md`: site #5 → `(vaults, AMM, lending, perps/margin, staking, Sui-native
   pitfalls)`; amend the "no application code, build system, or test suite" sentence with the
   `tests/fixtures/` clause; add the fixture build loop (fixtures.md
   `each_fixture_builds_clean` command) to the Commands block; add `docs/exploit-sources.md`
   and `tests/fixtures/<class-slug>/` lines to the layout tree — traces to release-wiring.md
   §Enumeration sites #5, §Additional `CLAUDE.md` edits; five_enumeration_sites_updated,
   claude_md_mentions_fixtures_and_sources; AC-6, AC-7; fixtures.md §Interaction with other specs
6. [implement] Bump `plugins/sui-ai/.claude-plugin/plugin.json` `version` to `2.3.0` (no other
   key; no `agents`/`commands` field; `.claude-plugin/marketplace.json` untouched), then run
   every release-wiring.md automated check that does not need git history — traces to
   release-wiring.md §Version; version_is_2_3_0, manifests_parse, marketplace_unchanged,
   no_agents_or_commands_field, no_sibling_plugin_dir, playbook_in_companion_dir,
   plugin_root_prefix_present; AC-1, AC-4, AC-5, AC-9; coverage-checks.md
   §plugin_version_bumped_in_same_change; AC-15; perps-playbook.md AC-6
**Entry criteria**: Chunks 2, 3 and 4 closed (all other plugin content is final so the bump
ships with it).
**Exit criteria**: every gate below passes; `git diff main --stat -- .claude-plugin/marketplace.json`
is empty.
**Gates**: `python3 -c "import json;d=json.load(open('plugins/sui-ai/.claude-plugin/plugin.json'));print(d['version']);assert 'agents' not in d and 'commands' not in d" | grep -qx 2.3.0`;
`python3 -m json.tool plugins/sui-ai/.claude-plugin/plugin.json >/dev/null && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null`; `git diff --quiet main -- .claude-plugin/marketplace.json && [ "$(git status --porcelain -- .claude-plugin/marketplace.json | wc -l | tr -d ' ')" = 0 ]` (marketplace_unchanged — no chunk ever edits it, so `main` is the right base); `[ "$(ls plugins)" = sui-ai ]`; `test -f $F`;
`awk '/^\| Reference \| Load when \|/,/^$/' $D | grep -c '^| `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/'` = 7; `grep -cF '| `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md` |' $D` = 1 and that line matches `load together with|also load` (companion_table_row_present: first cell is the perps path); the lending row (`grep -F '| `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-lending-and-liquidation.md` |' $D`) contains `defi-perps-and-margin.md`;
`grep -iE 'sui-native-pitfalls\.md.*\|.*oracle' $D | wc -l` = 1;
`awk '/^## PHASE 8B/,/^## PHASE 9/' $D | grep 'Lending / margin' | grep -q 'defi-lending-and-liquidation.md' && awk '/^## PHASE 8B/,/^## PHASE 9/' $D | grep 'Lending / margin' | grep -q 'defi-perps-and-margin.md'`;
`grep -rnE '(^|[^/])(verification-and-false-positives|defi-shares-and-vaults|defi-amm-and-slippage|defi-lending-and-liquidation|defi-staking-and-rewards|sui-native-pitfalls|defi-perps-and-margin)\.md' $D $P/*.md | grep -v CLAUDE_PLUGIN_ROOT | wc -l` = 0;
`grep -rnE '(^|[[:space:]`(])(\.\./|\./)[A-Za-z0-9_.-]+|plugins/sui-ai/' plugins/sui-ai/agents/ | wc -l` = 0; `grep -c CLAUDE_PLUGIN_ROOT $D` ≥ 3 (baseline); `git diff --name-only "$BASE" | grep -vE '^(plugins/sui-ai/|CLAUDE\.md$|docs/)' | wc -l` = 0 (this chunk's own changes: driver, `plugin.json`, `CLAUDE.md`);
`sed -n '1,14p' $D | grep -c perps` ≥ 1; `grep -n 'Protocol-archetype playbook' $D | grep -q perps`; `grep -n 'Sui-native pitfalls)' CLAUDE.md | grep -q perps`; `grep -rn 'vaults/AMM/lending/staking\|vault / AMM / lending / staking\|lending, staking, Sui-native' plugins CLAUDE.md | wc -l` = 0;
`grep -c 'tests/fixtures' CLAUDE.md` ≥ 1 and `grep -c 'docs/exploit-sources.md' CLAUDE.md` ≥ 1.

### Chunk 6: Fixtures A — c11, c03, c06
**Goal**: Three fixtures compile with zero warnings under the S-2 variant, each with a
seven-heading README naming its CHK-/PB- ids and expected candidate locations.
**Depends on**: Chunk 0 (S-2 variant and the c11 scaffold). May run in parallel with Chunks 2–5 and 7.
**Tasks**:
1. [implement] Complete `tests/fixtures/c11-governance-capture`: replace the S-2 stub with a
   governance module (40–150 lines) where `vote` reads live balance, `QUORUM = 0`, `execute`
   is callable in the same tx as pass with no delay, the payload is an arbitrary
   `(address, u64)` transfer, and there is no vote-token lock; README with the seven headings,
   the trigger-grep hits for CHK-C11-0 and the six per-item outcomes, its `## Requirements`
   section spelling out each id individually (`CHK-C11-0`, `CHK-C11-1`, `CHK-C11-2`,
   `CHK-C11-3`, `CHK-C11-4`, `CHK-C11-5` — never range notation); `sui move build` clean;
   commit `Move.lock` — traces to fixtures.md §Class-slug list row c11, §Per-fixture README
   contract; readme_headings_fixed, readme_cites_valid_ids; AC-3, AC-5 (CHK-C11-0..5)
2. [implement] Create `tests/fixtures/c03-signed-value-reinterpretation`: perps-shaped module
   where a fee field is stored as raw `u256`/`u64` by a constructor with no range check, decoded
   as signed fixed-point (local stand-in type) on the fee path into a collateral delta, with the
   cap compared in the unsigned domain; README whose `## Requirements` section spells out
   `CHK-C3-1`, `CHK-C3-2`, `CHK-C3-3` and `PB-5` individually (never `CHK-C3-1..3`); clean build;
   `Move.lock` — traces to fixtures.md §Class-slug list row c03; AC-5 (CHK-C3-1..3, PB-5)
3. [implement] Create `tests/fixtures/c06-cross-version-state-desync`: modules `legacy` and `v2`
   both writing `Pool.reserve_x` from different balance sources, an admin function calling
   `package::make_immutable` while `legacy` holds funds, and an ungated `legacy` `public` entry
   point; README whose `## Requirements` section spells out `CHK-C6-1`, `CHK-C6-2`, `CHK-C6-3`
   individually; clean build; `Move.lock` — traces to fixtures.md §Class-slug list row c06;
   AC-5 (CHK-C6-1..3)
4. [verify] For the three directories: `Move.toml` has `edition = "2024"`, no `published-at`,
   `[dependencies]` presence matches the S-2 variant; `Move.lock`, `README.md`, ≥ 1
   `sources/*.move` exist; README headings in order; every cited `REQ-COV-0NN` exists in
   `docs/requirements/traceability.md` and every cited `CHK-`/`PB-` id exists in `docs/spec/`;
   each id this chunk's fixtures own appears spelled out in exactly one fixture README (the
   per-id grep that Chunk 8 runs over all 31, run early here); any unavoidable lint is silenced with a targeted
   `#[allow(...)]` plus comment, never `warnings = "allow"` — traces to fixtures.md §Fixture
   content rules, §`Move.toml` contract; each_fixture_has_move_toml_lock_readme_sources,
   move_toml_has_no_published_at_and_edition_2024, dependency_variant_uniform,
   readme_headings_fixed, readme_cites_valid_ids; AC-1, AC-2, AC-3
**Entry criteria**: Chunk 0 closed; `tests/fixtures/README.md` carries the variant sentence.
**Exit criteria**: three clean builds; gates pass; no file under `plugins/` changed by this chunk.
**Gates**: `rc=0; for d in tests/fixtures/c11-governance-capture/ tests/fixtures/c03-signed-value-reinterpretation/ tests/fixtures/c06-cross-version-state-desync/; do out=$(cd "$d" && export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome" && sui move build 2>&1 </dev/null) || rc=1; grep -qiE '^(warning|error)' <<<"$out" && rc=1; done; exit $rc`;
`for d in <same three>; do test -f $d/Move.toml && test -f $d/Move.lock && test -f $d/README.md && ls $d/sources/*.move >/dev/null || exit 1; done`;
`grep -L published-at <three Move.toml>` lists all three; `grep -l 'edition = "2024"' <three Move.toml>` lists all three; `grep -rl 'warnings = "allow"' tests/fixtures | wc -l` = 0;
per fixture directory `$d`: `(cd "$d" && awk '/^```/{c=!c; next} !c && /^#/' README.md)` prints exactly `# Fixture: <slug>`, `## Class`, `## Mirrored incident`, `## Requirements`, `## Expected finding`, `## Expected noise`, `## Build` in that order (code-block lines excluded); `for id in $(grep -ohE 'REQ-COV-0[0-9]{2}' $d/README.md | sort -u); do grep -q "$id" docs/requirements/traceability.md || { echo "$id"; exit 1; }; done`; `for id in $(grep -ohE '(CHK-C[0-9]+-[0-9]+|PB-[0-9]+)' $d/README.md | sort -u); do grep -rqw "$id" docs/spec/ || { echo "$id"; exit 1; }; done` (readme_cites_valid_ids, both halves);
`for id in CHK-C11-0 CHK-C11-1 CHK-C11-2 CHK-C11-3 CHK-C11-4 CHK-C11-5 CHK-C3-1 CHK-C3-2 CHK-C3-3 PB-5 CHK-C6-1 CHK-C6-2 CHK-C6-3; do [ "$(grep -lw "$id" tests/fixtures/*/README.md | wc -l | tr -d ' ')" = 1 ] || { echo "$id"; exit 1; }; done` (ids owned by these three fixtures, spelled out);
`git diff --name-only "$BASE" -- plugins/ | wc -l` = 0 and `git status --porcelain -- plugins/ | wc -l` = 0 (this chunk's own changes); both manifest parses.

### Chunk 7: Fixtures B — c07, c08, c09
**Goal**: Three more fixtures (lending/oracle classes) compile clean with contract READMEs.
**Depends on**: Chunk 0. May run in parallel with Chunks 2–6.
**Tasks**:
1. [implement] Create `tests/fixtures/c07-thin-collateral-recursive-borrow`: collateral listing
   with no supply/borrow cap; `borrow` + `supply` of the same asset callable in one PTB with no
   per-asset loop bound; oracle adapter accepting a single last-trade price; permissionless
   `refresh_price` with no deviation gate; README whose `## Requirements` section spells out
   `CHK-C7-1`, `CHK-C7-2`, `CHK-C7-3`, `CHK-C7-4` individually; clean build; `Move.lock` —
   traces to fixtures.md §Class-slug list row c07; AC-5 (CHK-C7-1..4)
2. [implement] Create `tests/fixtures/c08-oracle-ratio-feed-misconfig`: a ratio (LST/base) feed
   consumed as a USD price; `set_feed` with no sanity band; growth-cap setter updating `ratio`
   without `ratio_timestamp`; README spelling out `CHK-C8-1`, `CHK-C8-2`, `CHK-C8-3`
   individually; clean build; `Move.lock` — traces to
   fixtures.md §Class-slug list row c08; AC-5 (CHK-C8-1..3)
3. [implement] Create `tests/fixtures/c09-oracle-authority-unpinned`: consumer stores only an
   aggregator object reference (local stand-in struct with `authority`, `queue`, `price`,
   `timestamp` fields), never pins `object::id` or the expected queue/authority, accepts any
   single update with no per-update move bound; deposit and withdraw priced by the same feed
   with no cooldown; README spelling out `CHK-C9-1`, `CHK-C9-2`, `CHK-C9-3`, `CHK-C9-4`
   individually and noting the S-1 outcome (the fixture violates under either); clean build; `Move.lock` — traces to fixtures.md §Class-slug list row c09;
   AC-5 (CHK-C9-1..4); coverage-checks.md §C9 Spike S-1 fallback paragraph
4. [verify] Same per-directory checks as Chunk 6 task 4 for these three directories — traces to
   fixtures.md §each_fixture_has_move_toml_lock_readme_sources,
   move_toml_has_no_published_at_and_edition_2024, dependency_variant_uniform,
   readme_headings_fixed, readme_cites_valid_ids; AC-1, AC-2, AC-3
**Entry criteria**: Chunk 0 closed.
**Exit criteria**: three clean builds; gates pass; `plugins/` untouched by this chunk.
**Gates**: the Chunk 6 gate commands with the three directories `c07-thin-collateral-recursive-borrow`, `c08-oracle-ratio-feed-misconfig`, `c09-oracle-authority-unpinned` (build loop — i.e. `rc=0; for d in tests/fixtures/c07-thin-collateral-recursive-borrow/ tests/fixtures/c08-oracle-ratio-feed-misconfig/ tests/fixtures/c09-oracle-authority-unpinned/; do out=$(cd "$d" && export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome" && sui move build 2>&1 </dev/null) || rc=1; grep -qiE '^(warning|error)' <<<"$out" && rc=1; done; exit $rc`, file presence, `Move.toml` checks, per-directory README heading and `readme_cites_valid_ids` loops); the per-id loop over `CHK-C7-1 CHK-C7-2 CHK-C7-3 CHK-C7-4 CHK-C8-1 CHK-C8-2 CHK-C8-3 CHK-C9-1 CHK-C9-2 CHK-C9-3 CHK-C9-4` (each in exactly one fixture README); `git diff --name-only "$BASE" -- plugins/ | wc -l` = 0 and `git status --porcelain -- plugins/ | wc -l` = 0; both manifest parses.

### Chunk 8: Fixtures C — c12, c20, perps-funding; index README; fixture gate
**Goal**: All nine fixtures exist, build clean under one variant, and the index README maps
slugs to classes, requirement ids and expected candidates with the C19 exemption.
**Depends on**: Chunk 6, Chunk 7.
**Tasks**:
1. [implement] Create `tests/fixtures/c12-bridge-single-verifier`: `VerifierSet { members:
   vector<address>, threshold: 1 }` accepted at construction; replay key is `nonce` only;
   `refund` pays `claimed_amount` not bounded by `deposited`; README spelling out `CHK-C12-1`,
   `CHK-C12-2`, `CHK-C12-3` individually; clean
   build; `Move.lock` — traces to fixtures.md §Class-slug list row c12; AC-5 (CHK-C12-1..3)
2. [implement] Create `tests/fixtures/c20-perps-market-manipulation`: `set_funding_rate`
   permissionless and unbounded; `match` with no `taker != maker` owner check and mark price
   taken from the last fill; `set_maintenance_margin` with no open-position re-check; README
   spelling out `PB-2`, `PB-3`, `PB-4` individually; clean build; `Move.lock` — traces to fixtures.md §Class-slug list row c20;
   AC-5 (PB-2..4)
3. [implement] Create `tests/fixtures/perps-funding-settlement-ordering`: `increase_position` /
   `add_collateral` mutate size/margin before `settle_funding` is called; README citing `PB-1`;
   clean build; `Move.lock` — traces to fixtures.md §Class-slug list row perps-funding; AC-5 (PB-1)
4. [implement] Complete `tests/fixtures/README.md`: one table `Slug | Class | Incident |
   Requirement IDs | Expected candidate (short)` with nine rows whose first cell is the bare
   directory slug in backticks (`` `c03-signed-value-reinterpretation` `` …, nothing else in the
   cell) matching the directories, the
   C19 exemption note ("REQ-COV-039 is advisory and must not produce a finding; no fixture"), and
   the S-2 dependency-variant statement already present — traces to fixtures.md §Index
   `tests/fixtures/README.md`; index_table_complete; AC-4, AC-2 (variant recorded)
5. [verify] Run the full fixtures.md automated list over all nine directories; confirm every
   one of the 31 CHK-*/PB-* ids (CHK-C3-1..3, C6-1..3, C7-1..4, C8-1..3, C9-1..4, C11-0..5,
   C12-1..3, PB-1..5) appears spelled out in exactly one fixture README, no README cites an id
   absent from the specs, and CHK-C19-1 appears in none; confirm no file under `plugins/` is
   changed by this chunk — traces to fixtures.md §Automated (all
   nine checks, `no_plugin_files_touched_by_fixture_commits` as the working-tree form); AC-1 … AC-6
**Entry criteria**: Chunks 6 and 7 closed (six fixtures built).
**Exit criteria**: all nine fixtures build clean in one loop; index complete; 31-id coverage
holds.
**Gates**: `[ "$(ls -d tests/fixtures/*/ | wc -l | tr -d ' ')" = 9 ]` and `ls tests/fixtures | grep -v README.md | paste -sd' ' -` = `c03-signed-value-reinterpretation c06-cross-version-state-desync c07-thin-collateral-recursive-borrow c08-oracle-ratio-feed-misconfig c09-oracle-authority-unpinned c11-governance-capture c12-bridge-single-verifier c20-perps-market-manipulation perps-funding-settlement-ordering`;
`rc=0; for d in tests/fixtures/*/; do out=$(cd "$d" && export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome" && sui move build 2>&1 </dev/null) || rc=1; grep -qiE '^(warning|error)' <<<"$out" && rc=1; done; exit $rc`;
`for d in tests/fixtures/*/; do test -f $d/Move.toml && test -f $d/Move.lock && test -f $d/README.md && ls $d/sources/*.move >/dev/null || exit 1; done`;
`[ "$(grep -L published-at tests/fixtures/*/Move.toml | wc -l | tr -d ' ')" = 9 ]`; `[ "$(grep -l 'edition = "2024"' tests/fixtures/*/Move.toml | wc -l | tr -d ' ')" = 9 ]`; `n=$(grep -l '^\[dependencies\]' tests/fixtures/*/Move.toml | wc -l | tr -d ' '); [ "$n" = 0 ] || [ "$n" = 9 ]`;
`[ "$(grep -cE '^\| `?(c[0-9]{2}-|perps-)' tests/fixtures/README.md)" = 9 ]` and `diff <(grep -oE '^\| `?(c[0-9]{2}|perps)-[a-z0-9-]+' tests/fixtures/README.md | sed -E 's/^\| `?//' | sort) <(ls -d tests/fixtures/*/ | xargs -n1 basename | sort)` is empty (index_table_complete: slugs equal directory names, optional backtick allowed); `grep -q 'REQ-COV-039' tests/fixtures/README.md && grep -qiE 'exempt|no fixture' tests/fixtures/README.md`;
`for id in $(grep -ohE '(CHK-C[0-9]+-[0-9]+|PB-[0-9]+)' tests/fixtures/*/README.md | sort -u); do grep -rqw "$id" docs/spec/ || { echo "$id"; exit 1; }; done` and `for id in $(grep -ohE 'REQ-COV-0[0-9]{2}' tests/fixtures/*/README.md | sort -u); do grep -q "$id" docs/requirements/traceability.md || { echo "$id"; exit 1; }; done` (readme_cites_valid_ids over all nine); per-directory README heading loop from Chunk 6 over all nine (readme_headings_fixed);
`for id in CHK-C3-1 CHK-C3-2 CHK-C3-3 CHK-C6-1 CHK-C6-2 CHK-C6-3 CHK-C7-1 CHK-C7-2 CHK-C7-3 CHK-C7-4 CHK-C8-1 CHK-C8-2 CHK-C8-3 CHK-C9-1 CHK-C9-2 CHK-C9-3 CHK-C9-4 CHK-C11-0 CHK-C11-1 CHK-C11-2 CHK-C11-3 CHK-C11-4 CHK-C11-5 CHK-C12-1 CHK-C12-2 CHK-C12-3 PB-1 PB-2 PB-3 PB-4 PB-5; do [ "$(grep -lw "$id" tests/fixtures/*/README.md | wc -l | tr -d ' ')" = 1 ] || { echo "$id"; exit 1; }; done`; `grep -rlw CHK-C19-1 tests/fixtures | wc -l` = 0;
`git diff --name-only "$BASE" -- plugins/ | wc -l` = 0 and `git status --porcelain -- plugins/ | wc -l` = 0 (this chunk's own changes); both manifest parses.

### Chunk 9: End-to-end verification and PR body
**Goal**: Every automated check in all six specs passes from a clean tree; the traceability
matrix's Test and Implementation columns are filled for all 72 live rows; the PR body text the
orchestrator needs exists.
**Depends on**: Chunk 1, Chunk 5, Chunk 8.
**Tasks**:
1. [verify] Re-run the complete `### Automated` lists of exploit-sources.md (10),
   coverage-checks.md (18, `plugin_version_bumped_in_same_change` read as "version is 2.3.0 in
   the tree"), perps-playbook.md (14; `lending_margin_content_untouched` against `main`),
   fixtures.md (9) and release-wiring.md (the 13 checks that do not need commit history or a PR)
   as the shell commands in this chunk's **Gates** list below (every check id has an owning
   command there; the list is the end-state form of the Chunk 1–8 gates, not their union), and
   record a pass/fail line per check id — traces to overview.md §Verification; exploit-sources.md, coverage-checks.md,
   perps-playbook.md, fixtures.md, release-wiring.md §Automated (every check id)
2. [verify] Re-run the six overview.md spec-set checks (`every_live_requirement_owned_once`,
   `traceability_spec_column_filled`, `all_specs_have_required_sections`,
   `landing_headings_consistent_across_specs` — now also against the implemented files with
   `grep -F`, `fixture_slugs_consistent`, `high_uncertainty_sections_have_spike_and_fallback`)
   — traces to overview.md §Automated (all six)
3. [implement] Fill any still-empty `Test` / `Implementation` cell in
   `docs/requirements/traceability.md` for the 72 live rows (Implementation = file → heading or
   fixture slug; Test = check id(s) and/or fixture slug; REQ-REL-007 stays empty) and confirm
   with `awk -F'|' '/^\| REQ-/ && $2 !~ /Deprecated/ && ($4 ~ /^ *$/ || $5 ~ /^ *$/)' docs/requirements/traceability.md | wc -l` = 0 (restricted to data rows so frontmatter, title and prose lines cannot count) — traces to
   coverage-checks.md §Content-level evidence rule (REQ-COV-040); overview.md
   §traceability_spec_column_filled
4. [implement] Write `docs/handoff/pr-body.md` with the six fixed PR sections: Why (RS-001
   summary, cutoff 2026-10-30); Audit-behaviour rationale table `Class | Check IDs | File →
   heading | What the auditor now does differently | Incident(s) it would have caught` with rows
   C3, C6, C7, C8, C9, C11, C12, C19, perps/C17/C20; the REQ-COV-040 table `CHK-ID | file |
   heading | first words` (one row per CHK-* and PB-*); Version 2.2.0 → 2.3.0 and why minor;
   Non-plugin artifacts (sources file, nine-of-nine fixture compile result, toolchain, variant);
   Checklist (manifests parse, five enumeration sites, `renames` untouched,
   `no_bare_companion_mention` clean, any wrapped name/path lines confirmed by eye) — traces to
   release-wiring.md §Branch and PR; pr_exists_to_main_with_rationale_table (body content);
   AC-8; coverage-checks.md §Content-level evidence rule; AC-13
5. [verify] Record for the orchestrator the commit-shape requirements it must satisfy at
   commit time (`feat(sui-move-auditor): <summary> (v2.3.0)` on the commit touching
   `plugin.json` together with at least one `plugins/sui-ai/agents/` file; docs-only,
   fixture-only and CLAUDE.md-only commits leave `plugin.json` unchanged; `feature/` branch; PR
   to `main` via `gh pr create` with `docs/handoff/pr-body.md`) as a closing note in
   `docs/handoff/pr-body.md` — traces to release-wiring.md §bump_commit_subject_names_version,
   bump_and_content_same_commit, non_plugin_commits_do_not_bump, branch_prefix; AC-1, AC-8, AC-10
6. [verify] Optional (not a gate; operator decision 8): run `sui-ai:sui-move-auditor` against
   `tests/fixtures/c03-signed-value-reinterpretation`, `c09-oracle-authority-unpinned`,
   `c11-governance-capture` and `c20-perps-market-manipulation`, confirm candidates at the
   README-named locations with severity ≤ Medium and that both lending and perps playbooks are
   reported loaded for c20; record the result in the PR body's Non-plugin artifacts section —
   traces to coverage-checks.md §Manual; perps-playbook.md §Manual; fixtures.md §Manual
**Entry criteria**: Chunks 1, 5 and 8 closed.
**Exit criteria**: every check id in task 1 and 2 reports pass; traceability has no empty
Test/Implementation cell on live rows; `docs/handoff/pr-body.md` exists with six sections.
**Gates** (explicit end-state list; every command must hold on the final tree with all of Chunks 0–8 in HEAD; NO isolation checks except this chunk's own-changes line at the end):
- *release-wiring / version*: `python3 -c "import json;d=json.load(open('plugins/sui-ai/.claude-plugin/plugin.json'));print(d['version']);assert 'agents' not in d and 'commands' not in d" | grep -qx 2.3.0` (version_is_2_3_0, no_agents_or_commands_field, coverage-checks `plugin_version_bumped_in_same_change` read as tree state); both manifest parses (manifests_parse); `git diff --quiet main -- .claude-plugin/marketplace.json` (marketplace_unchanged); `[ "$(ls plugins)" = sui-ai ]` (no_sibling_plugin_dir); `test -f $F` (playbook_in_companion_dir, playbook_file_exists_in_companion_dir); `grep -rnE '(^|[[:space:]`(])(\.\./|\./)[A-Za-z0-9_.-]+|plugins/sui-ai/' plugins/sui-ai/agents/ | wc -l` = 0 (no_relative_or_repo_paths_in_plugin); `grep -c CLAUDE_PLUGIN_ROOT $D` ≥ 3 (plugin_root_prefix_present).
- *companion wiring*: `grep -rnE '(^|[^/])(verification-and-false-positives|defi-shares-and-vaults|defi-amm-and-slippage|defi-lending-and-liquidation|defi-staking-and-rewards|sui-native-pitfalls|defi-perps-and-margin)\.md' $D $P/*.md | grep -v CLAUDE_PLUGIN_ROOT | wc -l` = 0 (no_bare_companion_mention; implies no_bare_companion_mention_perps); `awk '/^\| Reference \| Load when \|/,/^$/' $D | grep -c '^| `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/'` = 7 (companion_table_all_full_path); `grep -cF '| `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/defi-perps-and-margin.md` |' $D` = 1 and that line matches `load together with|also load`, and the lending row contains `defi-perps-and-margin.md` (companion_table_row_present); `grep -iE 'sui-native-pitfalls\.md.*\|.*oracle' $D | wc -l` = 1 (sui_native_load_condition_mentions_oracle); the Chunk 5 Phase 8B command (phase_8b_row_names_both); `sed -n '1,14p' $D | grep -c perps` ≥ 1, `grep -n 'Protocol-archetype playbook' $D | grep -q perps`, `grep -n 'Sui-native pitfalls)' CLAUDE.md | grep -q perps`, `grep -rn 'vaults/AMM/lending/staking\|vault / AMM / lending / staking\|lending, staking, Sui-native' plugins CLAUDE.md | wc -l` = 0 (five_enumeration_sites_updated); `grep -c 'tests/fixtures' CLAUDE.md` ≥ 1 and `grep -c 'docs/exploit-sources.md' CLAUDE.md` ≥ 1 (claude_md_mentions_fixtures_and_sources).
- *coverage-checks headings*: `for h in '### 5.3a High-signal correctness greps (cheap, high severity)' '### 6.14 Package Upgrade Safety' '### 7.2 Oracle & Price Manipulation' '## PHASE 1 — CONTEXT GATHERING' '### 6.8 Governance, Voting & Weight Safety'; do [ "$(grep -cF -- "$h" $D)" = 1 ] || { echo "$h"; exit 1; }; done`; `grep -cF '### 6.8 Weight & Governance Safety' $D` = 0; `for h in '## Market creation & configuration validation' '## Oracle staleness & price representability'; do [ "$(grep -cF -- "$h" $P/defi-lending-and-liquidation.md)" = 1 ] || exit 1; done`; `grep -cF '## Oracle integrations (Pyth / Switchboard / custom feeds)' $P/sui-native-pitfalls.md` = 1; `grep -cF '## Cross-chain / bridge / ZK' $P/sui-native-pitfalls.md` = 1; `grep -cF '## Move-specific false-positive catalog ("looks vulnerable, is safe")' $P/verification-and-false-positives.md` = 1; `grep -cF '## Fees, funding and collateral deltas as signed-value sinks' $F` = 1 (headings_exist_verbatim, all files).
- *coverage-checks content*: the Chunk 4 gate commands for 5.3a (`c3_bullets_in_5_3a`, with the one-to-three bound computed against `git show main:$D`), 6.14 (`c6_three_items_in_6_14`, `c6_floor_stated`), 6.8 (`c11_trigger_and_five_items`), 7.2 (`c7_4_refresh_in_7_2`, `c9_driver_load_instruction`) and Phase 1 (`c19_step_10`); the Chunk 3 gate commands for the lending blocks (`c7_in_market_creation`, `c7_depth_unknown_path`, `c7_c8_in_oracle_staleness`), the oracle section (`c9_section_and_table`, Pyth row manual read), cross-chain (`c12_three_bullets`) and the catalog (`catalog_rows_added`); `no_incident_as_subject` and `style_lengths` as the manual counts of Chunk 3 task 6 and Chunk 4 task 6 re-done once over the final text.
- *perps-playbook*: the Chunk 2 gate commands (`load_when_opener_states_dual_load`, `six_fixed_headings_present_in_order`, `preamble_states_cap`, `pb1_settle_first` … `pb5_points_to_driver`, `known_good_section_present`, the `$F` bare-mention grep); the Chunk 3 section-diff command `git show main:$P/defi-lending-and-liquidation.md | sed -n '/^## Self-liquidation & self-match/,/^## Known-good/p' > "$TMPDIR/selfliq_main.txt"; sed -n '/^## Self-liquidation & self-match/,/^## Known-good/p' $P/defi-lending-and-liquidation.md > "$TMPDIR/selfliq_tree.txt"; diff "$TMPDIR/selfliq_main.txt" "$TMPDIR/selfliq_tree.txt" | grep -c '^<'` = 0 (lending_margin_content_untouched, against `main`; process-substitution form in Chunk 3 is equivalent).
- *exploit-sources*: the Chunk 1 gate commands in full (sources_file_exists_outside_plugins, frontmatter_has_cutoff_and_spike, eleven_sources_present_in_rank_order, every_source_has_full_field_block, last_checked_is_date_or_never, primary_set_names_three_sources_with_filter_field, retry_list_covers_unverified_sources, procedure_has_required_steps_in_order, strict_after_rule_stated) in their corrected forms — in particular `grep -cE '^- \*\*Last checked:\*\*' docs/exploit-sources.md` = 11 and `grep -E '^- \*\*Last checked:\*\*' docs/exploit-sources.md | grep -vcE ':\*\* (`?[0-9]{4}-[0-9]{2}-[0-9]{2}`?|never attempted)$'` = 0 (last_checked_is_date_or_never), the frontmatter-only `[2025-10-30, 2026-10-30]` pair of `sed` counts (1 / 0) and `grep '^#\{1,2\} ' docs/exploit-sources.md | paste -sd'|' -` = `# Exploit Sources|## Current cutoff|## Primary set|## Sources (ranked)|## Retry list|## Rerun procedure|## Change log` (seven-section order); `git diff --name-only main -- .github/ scripts/ | wc -l` = 0 and `ls scripts .github 2>/dev/null | wc -l` = 0 (no_automation_shipped, end-state form).
- *fixtures*: `[ "$(ls -d tests/fixtures/*/ | wc -l | tr -d ' ')" = 9 ]` and the Chunk 8 slug-list equality (all_nine_fixture_dirs_exist); `rc=0; for d in tests/fixtures/*/; do out=$(cd "$d" && export SUI_CONFIG_DIR="$TMPDIR/suicfg" MOVE_HOME="$TMPDIR/movehome" && sui move build 2>&1 </dev/null) || rc=1; grep -qiE '^(warning|error)' <<<"$out" && rc=1; done; exit $rc` (each_fixture_builds_clean; the two exports and `</dev/null` are mandatory in the sandbox, see §Conventions); the Chunk 8 file-presence loop (each_fixture_has_move_toml_lock_readme_sources); the two `grep -L published-at` / `grep -l 'edition = "2024"'` = 9 checks (move_toml_has_no_published_at_and_edition_2024); the `[dependencies]` count 0-or-9 check (dependency_variant_uniform); the per-directory README heading loop over all nine (readme_headings_fixed); the Chunk 8 CHK-/PB- and REQ-COV- validity loops (readme_cites_valid_ids); the Chunk 8 index row count + slug `diff` + `REQ-COV-039` grep (index_table_complete); the 31-id exactly-one loop and `grep -rlw CHK-C19-1 tests/fixtures | wc -l` = 0; `grep -rl 'warnings = "allow"' tests/fixtures | wc -l` = 0; `git log --format=%H main..HEAD -- tests/ | while read c; do [ "$(git show --format= --name-only "$c" -- plugins/ | wc -l | tr -d ' ')" = 0 ] || git show --format= --name-only "$c" -- plugins/ | grep -q 'sui-move-auditor' ; done` is informational only — `no_plugin_files_touched_by_fixture_commits` is confirmed at PR review from the orchestrator's commit split (Chunk 9 task 5).
- *overview spec-set* (task 2): `grep -h '^requires:' docs/spec/*.md | grep -oE 'REQ-[A-Z]+-[0-9]{3}' | sort | uniq -d | wc -l` = 0 and `grep -h '^requires:' docs/spec/*.md | grep -oE 'REQ-[A-Z]+-[0-9]{3}' | sort -u > "$TMPDIR/req_specs.txt"; awk -F'|' '/^\| REQ-/ && $2 !~ /Deprecated/ {gsub(/ /,"",$2); print $2}' docs/requirements/traceability.md | sort -u > "$TMPDIR/req_live.txt"; diff "$TMPDIR/req_specs.txt" "$TMPDIR/req_live.txt" | wc -l` = 0 with `wc -l < "$TMPDIR/req_live.txt"` = 72 (every_live_requirement_owned_once); `awk -F'|' '/^\| REQ-/ && $2 !~ /Deprecated/ {gsub(/[` ]/,"",$3); if ($3=="" || system("test -f docs/spec/" $3)!=0) print $2}' docs/requirements/traceability.md | wc -l` = 0 (traceability_spec_column_filled; the Spec cell is column 3, the file name is checked for existence); `for f in docs/spec/*.md; do for h in '## Context' '## Design' '## Verification' '### Automated' '### Manual' '### Acceptance Criteria'; do grep -qF -- "$h" "$f" || { echo "$f $h"; exit 1; }; done; done` (all_specs_have_required_sections); `awk '/^\| C[0-9]/' docs/spec/overview.md | grep -oE '`#+ [^`]+`' | tr -d '`' | sort -u | while read -r h; do grep -qF -- "$h" docs/spec/coverage-checks.md docs/spec/perps-playbook.md && grep -qF -- "$h" $D $P/*.md || { echo "$h"; exit 1; }; done` (landing_headings_consistent_across_specs, extended to the implemented files with `grep -F`); `grep -oE '\bc[0-9]{2}-[a-z0-9-]+|perps-funding-settlement-ordering' docs/spec/fixtures.md | sort -u > "$TMPDIR/slugs_fx.txt"; grep -ohE '\bc[0-9]{2}-[a-z0-9-]+|perps-funding-settlement-ordering' docs/spec/coverage-checks.md docs/spec/perps-playbook.md | sort -u > "$TMPDIR/slugs_cc.txt"; ls tests/fixtures | grep -v README.md | sort > "$TMPDIR/slugs_tree.txt"; diff "$TMPDIR/slugs_fx.txt" "$TMPDIR/slugs_cc.txt" | wc -l` = 0 and `diff "$TMPDIR/slugs_fx.txt" "$TMPDIR/slugs_tree.txt" | wc -l` = 0 (fixture_slugs_consistent); `grep -rc 'high-uncertainty\]' docs/spec/coverage-checks.md docs/spec/fixtures.md` = 1 each, and MANUAL: read the two marked sections and confirm each names a tool-call budget and a fallback design (high_uncertainty_sections_have_spike_and_fallback — the budget/fallback wording is prose, so this one is a manual check).
- *this chunk*: `[ "$(awk -F'|' '/^\| REQ-/ && $2 !~ /Deprecated/ && ($4 ~ /^ *$/ || $5 ~ /^ *$/)' docs/requirements/traceability.md | wc -l | tr -d ' ')" = 0 ]` (traceability filled, data rows only); `grep -c '^## ' docs/handoff/pr-body.md` ≥ 6 and `grep -q 'Audit-behaviour rationale' docs/handoff/pr-body.md` and for each of C3 C6 C7 C8 C9 C11 C12 C19 perps `grep -q` matches; `git diff --name-only "$BASE" | grep -vE '^docs/(requirements/traceability\.md|handoff/pr-body\.md|plan\.md)$' | wc -l` = 0 (this chunk's own changes: traceability, PR body, plan ticks only).

## Replan Triggers

- **S-1 Outcome B** (Switchboard `Aggregator` exposes no readable `authority`, or the sources
  cannot be fetched within 5 tool calls) → adopt the fallback wording for the Switchboard row in
  Chunk 3 task 3 ("pin aggregator ID + queue ID + consumer-side staleness/variance") and note
  "fallback adopted; S-1 unresolved" in the C9 table; no other task changes. Replan only if the
  sources show a **third** shape (e.g. authority exists but no queue concept) — then redesign
  the CHK-C9-1 table row before Chunk 3 starts.
- **S-2 both variants fail** (implicit build warns/fails on 1.81.1 **and** neither
  `testnet-v1.81.1` nor `framework/testnet` resolves) → stop fixture chunks 6–8, replan the
  `Move.toml` contract with the operator (candidates: `mainnet-v1.81.x` tag, or a local
  `sui move new`-generated manifest as the template) before any fixture is written.
- **S-2 mixed result** (c11 builds implicit but a later fixture needs the explicit dependency)
  → the variant is repository-wide, never mixed: switch all nine `Move.toml` to the explicit
  variant, rebuild all, update the README sentence; if that is impossible for one fixture,
  replan that fixture's design (the vulnerable shape must not require a framework module the
  implicit set lacks).
- **A fixture cannot be made to compile with zero warnings** after two attempts at the
  vulnerable shape (e.g. the compiler rejects the raw-bits reinterpretation of C3, or a lint
  cannot be silenced with a targeted `#[allow]`) → replan that fixture only: keep the slug and
  README contract, change the Move shape to the nearest compiling expression of the same
  mechanism, and record the deviation under `## Expected noise`; if the mechanism itself cannot
  be expressed in Move 2024 edition, escalate — the class contract in coverage-checks.md may need
  a note that fixture-level evidence is partial for it.
- **`no_bare_companion_mention` cannot be made clean without breaking a heading** (a heading
  names a companion file as a concept) → per the spec, tolerated only when the same bullet gives
  the full path once; if a heading line itself matches, replan the heading text with the
  operator rather than silencing the grep.
- **A driver bullet cannot fit ≤ 6 wrapped lines while naming trigger, set, invariant, absence,
  gate, cap and carve-out** → split into two adjacent bullets (coverage-checks.md allows one to
  three for C3); if a class with a fixed single-bullet landing (CHK-C7-4, C9 load bullet) cannot
  fit, move detail into the playbook section it points at and re-verify the grep.
- **Spec staleness**: if any `docs/spec/*.md` `last_updated` becomes newer than this plan's
  `last_updated`, stop and rerun `plan`.

## Completed

(none yet)

## Risks

- **S-1 relies on network access** to `github.com`/`raw.githubusercontent.com`; the sandbox may
  need those hosts allow-listed. Mitigation: the fallback wording is fully specified, so a
  blocked fetch degrades to Outcome B without a replan.
- **`sui move build` needs the sandbox environment** described in §Conventions (the two
  exports, `</dev/null`, and — for the explicit variant — the pinned framework rev, which is
  cached locally; any other rev or the implicit variant may need network to `github.com` on
  the first build). Mitigation: every build gate line carries the exports; Chunk 0 performs the
  first build; if the implicit variant cannot fetch, S-2 falls back to the already-verified
  explicit pinned variant per its replan trigger.
- **`sui_native_load_condition_mentions_oracle` is fragile**: the regex
  `sui-native-pitfalls\.md.*\|.*oracle` matches any line with the filename, a later `|`, and
  "oracle". The 7.2 load bullet (Chunk 4 task 5) must not contain `|` after the path on that
  line, and CHK-C7-4's grep seeds (which contain `|`) must stay on their own bullet's lines.
  Mitigation: stated in the task; the Chunk 4 gate asserts the count is 0 (the companion-table
  row is not amended until Chunk 5, so any Chunk 4 hit is a `|` leaking into the 7.2 bullet) and
  the Chunk 5 and Chunk 9 gates assert it is exactly 1.
- **The decision-9 rewrite touches 25 driver lines** (27 corpus-wide), several inside wrapped bullets; a careless
  re-wrap could break "bold lead-in on the bullet line" greps or push a bullet past 6 lines.
  Mitigation: Chunk 5 task 3 re-runs the grep rather than trusting the baseline list, and the
  Chunk 5 gates include `plugin_root_prefix_present` and the full `no_bare_companion_mention`.
- **Chunks 4 and 5 both edit `$D`**; running them concurrently would conflict. Mitigation:
  Chunk 5 depends on Chunk 4; the fan-out signal is the `Depends on` field.
- **Fixture lint noise**: vulnerable shapes (self-transfer, unused `Clock`, public struct
  without abilities) may trigger Move 2024 lints. Mitigation: targeted `#[allow(lint(...))]`
  with a comment per fixtures.md; `warnings = "allow"` in `Move.toml` is forbidden and gated.
- **`readme_cites_valid_ids` for CHK-/PB- ids** is checked against the specs, which exist;
  REQ-COV ids are checked against `traceability.md`. The 31-id exactly-one loop catches a
  **missing** id (or one cited in two READMEs) only — it does not catch an **extra** or
  mistyped id such as `CHK-C7-5`; that is what the separate `readme_cites_valid_ids` validity
  loop (every CHK-/PB- id in a README must exist in `docs/spec/`) in the Chunk 6, 7 and 8 gates
  is for. Range notation (`CHK-C3-1..3`) satisfies neither loop, so every task requires ids
  spelled out individually.
- **Git-history checks** (`bump_commit_subject_names_version`, `non_plugin_commits_do_not_bump`,
  `branch_prefix`, `pr_exists_to_main_with_rationale_table`) cannot be satisfied by plan tasks
  because the orchestrator owns commits. Mitigation: Chunk 9 task 5 hands the orchestrator the
  exact commit split and subject; the verify stage checks them after commit.

## Open Questions

- **Where spike findings live.** The specs say S-1's result is recorded "in the section's table"
  and S-2's "in `tests/fixtures/README.md`", both of which do not exist when the spikes run.
  Default taken: record findings inline under the spike task in this plan at Chunk 0 close and
  copy them into those artifacts in Chunks 3 and 8. No operator decision is needed unless the
  orchestrator prefers a separate findings file.
- **Spec conflict on the first-run-window literal (for the spec owner).** exploit-sources.md
  line 39 fixes `first_run_window: "[2025-10-30, 2026-10-30]"` in the frontmatter and §Section
  order requires `## Current cutoff` to state the inclusive first-run window, while line 205
  (`strict_after_rule_stated`) requires the literal `[2025-10-30, 2026-10-30]` to appear
  exactly once in the file. Both cannot hold if the body repeats the bracketed form. Default
  taken (Chunk 1 task 1 and gates): the bracketed literal lives ONLY in the frontmatter; the
  body words the window as "from 2025-10-30 through 2026-10-30, inclusive". The spec owner may
  instead relax `strict_after_rule_stated` to "appears once in the frontmatter", in which case
  the gates here already pass unchanged.
- **PR body as a repository file.** release-wiring.md fixes the PR description content but not
  where a non-interactive pipeline stores it before `gh pr create`. Default taken:
  `docs/handoff/pr-body.md` (Chunk 9 task 4), which the orchestrator passes to `gh pr create
  --body-file`. Remove or keep after merge at the operator's discretion.
