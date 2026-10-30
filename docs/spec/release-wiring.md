---
status: Approved
last_updated: 2026-10-30
requires: [REQ-REL-001, REQ-REL-002, REQ-REL-003, REQ-REL-004, REQ-REL-005, REQ-REL-006, REQ-REL-008, REQ-REL-009, REQ-REL-010, REQ-REL-011, REQ-REL-012, REQ-REL-013]
---

# Release Wiring and Repository Conventions

## Context

The coverage change touches plugin content (driver, three existing playbooks, one new playbook)
and must land under the repository's mandatory conventions: one umbrella version bump, companion
references via `${CLAUDE_PLUGIN_ROOT}`, content inside `plugins/sui-ai/`, valid manifests, an
untouched `renames` map, synchronized playbook enumerations, prefixed branch and PR to `main`,
and a commit subject naming the version. This spec makes each of those concrete for this change
set and fulfils REQ-REL-001 … 006 and 008 … 013. (REQ-REL-007 is deprecated; its content — docs
edits never bump the plugin — is restated here only as a corollary of REQ-SRC-001.)

## Design

### Version (REQ-REL-001, REQ-REL-011, REQ-REL-012)

- New version (fixed): **`2.3.0`** in `plugins/sui-ai/.claude-plugin/plugin.json`. Rationale: a
  new playbook plus ~20 new checks is a feature addition with no breaking change to how the
  agent is invoked → minor bump from 2.2.0 (REQ-REL-012 forbids a patch bump; nothing justifies
  a major).
- Exactly one version bump for the whole change set, in the same commit (or PR) as the first
  plugin content change. Fixture-only, `docs/**`-only, and `CLAUDE.md`-only commits do not bump.
- Commit subject (fixed pattern): `feat(sui-move-auditor): <summary> (v2.3.0)` on the commit
  that changes `plugin.json`; conventional-commit format throughout; no attribution trailers
  (repository and operator conventions).
- `plugin.json` `description` is **not** required to change: it does not enumerate playbooks
  ("Currently ships the sui-move-auditor zero-trust security auditor…"). Optional: none.

### Change-set inventory (what is plugin content, what is not)

| Path | Kind | Bumps version? | Spec that defines the edit |
|---|---|---|---|
| `plugins/sui-ai/.claude-plugin/plugin.json` | manifest, `version` 2.2.0 → 2.3.0 | is the bump | this spec |
| `plugins/sui-ai/agents/sui-move-auditor.md` | driver: frontmatter `description`; companion table (new row + lending row suffix; `sui-native-pitfalls.md` row's load condition gains "oracle / third-party price-object consumption"; **all seven first-column cells rewritten to the full `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md` form**); Phase 1 step 10; 5.3a one to three bullets; 6.8 rename + trigger + 5 items; 6.14 three items; 7.2 CHK-C7-4 refresh bullet + explicit-load bullet for `sui-native-pitfalls.md`; Phase 8B row (**all archetype rows rewritten to the full-path form**); every in-text "see X.md" mention (lines ~59, 136, 496, 610, 614, 935 at the 2026-10-30 baseline) rewritten to the full-path form; Appendix C methodology line 8 | yes | `coverage-checks.md`, `perps-playbook.md`, this spec (enumerations) |
| `plugins/sui-ai/agents/sui-move-auditor/defi-perps-and-margin.md` | new playbook | yes | `perps-playbook.md` |
| `plugins/sui-ai/agents/sui-move-auditor/defi-lending-and-liquidation.md` | C7 (CHK-C7-1..3) / C8 bullets; any bare companion-file mention rewritten to full-path form | yes | `coverage-checks.md` |
| `plugins/sui-ai/agents/sui-move-auditor/sui-native-pitfalls.md` | C9 section, C12 bullets; any bare companion-file mention rewritten to full-path form | yes | `coverage-checks.md` |
| `plugins/sui-ai/agents/sui-move-auditor/verification-and-false-positives.md` | 4 catalog rows; any bare companion-file mention rewritten to full-path form | yes | `coverage-checks.md` |
| `plugins/sui-ai/agents/sui-move-auditor/{defi-shares-and-vaults,defi-amm-and-slippage,defi-staking-and-rewards}.md` | only where `no_bare_companion_mention` hits: bare companion-file mentions rewritten to full-path form (operator decision 9) | yes, if touched | this spec |
| `CLAUDE.md` | enumeration + fixtures note | no | this spec |
| `docs/exploit-sources.md` | new file | no (REQ-SRC-001 corollary) | `exploit-sources.md` |
| `tests/fixtures/**` | nine fixtures + index | no | `fixtures.md` |
| `.claude-plugin/marketplace.json` | **unchanged** | — | REQ-REL-006 |

### Companion wiring (REQ-REL-002, REQ-REL-003, REQ-REL-004)

- The new playbook is listed in the driver's "COMPANION REFERENCES" table with the load-when
  text fixed in `perps-playbook.md`.
- **Companion path rule (operator decision 9, strict; stated identically in
  `perps-playbook.md` §File and load trigger):** every mention of a companion playbook file in
  agent content — the companion table's first-column cells, the Phase 8B list, and every in-text
  "see X.md" mention in the driver or a playbook — uses the full
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md` form. The existing six table rows
  and four 8B rows are rewritten to that form in this cycle (edit owned by this spec; see the
  change-set inventory). Headings or prose that name a file as a concept are acceptable only if
  the same bullet also gives the full path once. Rationale: REQ-REL-002 as approved applies to
  every companion reference, and a reader of a single row or bullet must be able to load the
  file without consulting the table lead-in.
- The `sui-native-pitfalls.md` row's load condition gains "oracle / third-party price-object
  consumption" so the C9 oracle section is actually loaded for oracle consumers
  (`coverage-checks.md` §C9); the lending row gains the dual-load suffix (`perps-playbook.md`).
- Forbidden anywhere under `plugins/`: `./`, `../`, `plugins/sui-ai/...`, or absolute
  repository paths.
- Placement: the new playbook sits in `plugins/sui-ai/agents/sui-move-auditor/`; no new
  `plugins/<name>/` directory; `plugin.json` gains no `agents` or `commands` field.

### Enumeration sites (REQ-REL-008) — all five, fixed

Every place that lists the playbook set changes in the same change set:

| # | File:location | Current text | New text (fixed intent; wording may be tightened) |
|---|---|---|---|
| 1 | `sui-move-auditor.md` frontmatter `description` (line ~8) | `archetype playbooks (vaults/AMM/lending/staking)` | `archetype playbooks (vaults/AMM/lending/perps-margin/staking)` |
| 2 | `sui-move-auditor.md` "COMPANION REFERENCES" table | six rows, bare filenames | seven rows, every first cell in the full `${CLAUDE_PLUGIN_ROOT}` form; perps row after lending; lending row suffix (text in `perps-playbook.md`); `sui-native-pitfalls.md` row load condition + oracle |
| 3 | `sui-move-auditor.md` "PHASE 8B — PROTOCOL ARCHETYPE PLAYBOOKS" | four rows, bare filenames | all rows in the full `${CLAUDE_PLUGIN_ROOT}` form; "Lending / margin" names both files (text in `perps-playbook.md`) |
| 4 | `sui-move-auditor.md` Appendix C "Methodology" item 8 | `Protocol-archetype playbook (vault / AMM / lending / staking, as applicable)` | `Protocol-archetype playbook (vault / AMM / lending / perps-margin / staking, as applicable)` |
| 5 | `CLAUDE.md` §"Layout and how the pieces connect", Driver + playbooks bullet | `(vaults, AMM, lending, staking, Sui-native pitfalls)` | `(vaults, AMM, lending, perps/margin, staking, Sui-native pitfalls)` |

Site 4 was found by grep on 2026-10-30 and is not named in REQ-REL-008's examples; it is an
enumeration and is included so no stale list remains. `plugin.json` and `marketplace.json`
descriptions and `README.md` do not enumerate playbooks (grep-verified) and are out of scope.

Additional `CLAUDE.md` edits (documentation, no bump): (a) the sentence "There is no application
code, build system, or test suite" gains a clause noting `tests/fixtures/` (compile-only
acceptance fixtures for auditor checks, built with `sui move build`, not a test suite of the
plugin); (b) the "Commands" block gains the fixture build loop from `fixtures.md`; (c) the layout
tree gains `docs/exploit-sources.md` and `tests/fixtures/<class-slug>/` lines. Rationale: the
file is the agent-facing map of the repository; a reader must find the new artifacts from it.

### Manifest integrity (REQ-REL-005, REQ-REL-006)

- After the change: `python3 -m json.tool .claude-plugin/marketplace.json` and
  `python3 -m json.tool plugins/sui-ai/.claude-plugin/plugin.json` both exit 0.
- `.claude-plugin/marketplace.json` is not modified at all by this change set (`git diff
  --stat` shows no entry); in particular `renames` is byte-identical.

### Placement of checks (REQ-REL-013)

Each check lands where its target loads it; the decision table is `coverage-checks.md` §Class
inventory and `perps-playbook.md` §File and load trigger. Summary of the principle applied:
driver for Move/package/governance mechanics any target can exhibit (C3, C6, C11, C19);
lending playbook for collateral/feed configuration (CHK-C7-1..3, C8), with CHK-C7-4
(permissionless refresh, not lending-specific) in driver 7.2; `sui-native-pitfalls.md` for
third-party objects (C9 oracles, C12 bridges), its load condition amended so oracle consumers
load it; the new perps playbook for perps/margin
mechanics (operator decision 2), with margin targets also keeping the lending playbook
(REQ-COV-033). A non-matching target loads no new playbook and reads only the driver's additive
lines.

### Branch and PR (REQ-REL-009, REQ-REL-010)

- Branch name (fixed prefix): `feature/exploit-coverage-refresh-2026-10` (any `feature/` name is
  compliant; this one is the default).
- Delivered to `main` only via a pull request opened with `gh pr create`; merge, not rebase, if
  the branch must integrate `main` (operator convention).
- PR description contract (fixed sections): (1) **Why** — RS-001 summary and cutoff; (2)
  **Audit-behaviour rationale per check** — a table `Class | Check IDs | File → heading | What the
  auditor now does differently | Incident(s) it would have caught`, one row per class (C3, C6,
  C7, C8, C9, C11, C12, C19, perps/C17/C20), satisfying REQ-REL-010; (3) the REQ-COV-040 table
  (`CHK-ID | file | heading | first words`); (4) **Version** — 2.2.0 → 2.3.0 and why minor;
  (5) **Non-plugin artifacts** — `docs/exploit-sources.md`, `tests/fixtures/` with the compile
  result (nine of nine, toolchain `sui 1.81.1`, dependency variant); (6) **Checklist** —
  manifests parse, enumerations updated (five sites), `renames` untouched,
  `no_bare_companion_mention` clean.
- Commits are atomic by logical change; suggested split (not mandated): docs/sources; fixtures;
  plugin content + version bump (one commit, so the bump and the content it ships are never
  separated); CLAUDE.md.

### Interaction with other specs

- `coverage-checks.md` and `perps-playbook.md` define the content of the plugin edits listed in
  the inventory; this spec defines the wrapper (version, enumerations, manifests, branch, PR).
- `fixtures.md` and `exploit-sources.md` define the non-plugin artifacts whose commits must not
  bump the version.

## Verification

### Automated

- `version_is_2_3_0`: `python3 -c "import json;print(json.load(open('plugins/sui-ai/.claude-plugin/plugin.json'))['version'])"` prints `2.3.0`.
- `manifests_parse`: both `python3 -m json.tool` commands exit 0.
- `marketplace_unchanged`: `git diff --quiet <base>..HEAD -- .claude-plugin/marketplace.json`
  exits 0.
- `no_agents_or_commands_field`: `python3 -c` check that `plugin.json` has neither `agents` nor
  `commands` keys.
- `no_sibling_plugin_dir`: `ls plugins` prints exactly `sui-ai`.
- `playbook_in_companion_dir`: `test -f plugins/sui-ai/agents/sui-move-auditor/defi-perps-and-margin.md`.
- `no_relative_or_repo_paths_in_plugin`: `grep -rnE '(^|[[:space:]`(])(\.\./|\./)[A-Za-z0-9_.-]+|plugins/sui-ai/' plugins/sui-ai/agents/`
  returns zero lines — anchored to path context (a relative segment at a token boundary
  followed by a path component) so prose such as "e.g./" or a sentence-ending "./" cannot match
  (the existing files already satisfy this; the grep guards new text).
- `plugin_root_prefix_present`: `grep -c 'CLAUDE_PLUGIN_ROOT' plugins/sui-ai/agents/sui-move-auditor.md`
  is ≥ the current count (no prefix removed).
- `no_bare_companion_mention`: `grep -rnE '(^|[^/])(verification-and-false-positives|defi-shares-and-vaults|defi-amm-and-slippage|defi-lending-and-liquidation|defi-staking-and-rewards|sui-native-pitfalls|defi-perps-and-margin)\.md' plugins/sui-ai/agents/sui-move-auditor.md plugins/sui-ai/agents/sui-move-auditor/*.md | grep -v CLAUDE_PLUGIN_ROOT`
  returns zero lines: no companion-file mention remains outside a `${CLAUDE_PLUGIN_ROOT}` path on
  the same line (operator decision 9). A heading or concept mention is tolerated only when the
  same bullet carries the full path once; if such a bullet wraps so that the name and the path
  fall on different lines, the reviewer confirms by eye and records it in the PR checklist.
- `companion_table_all_full_path`: `awk '/^\| Reference \| Load when \|/,/^$/' plugins/sui-ai/agents/sui-move-auditor.md | grep -c '^| `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/'`
  equals 7.
- `sui_native_load_condition_mentions_oracle`: `grep -iE 'sui-native-pitfalls\.md.*\|.*oracle' plugins/sui-ai/agents/sui-move-auditor.md`
  returns exactly one line (the companion-table row).
- `five_enumeration_sites_updated`: `grep -c 'perps' <<< "$(sed -n '1,14p' plugins/sui-ai/agents/sui-move-auditor.md)"` ≥ 1 (site 1);
  companion table row present (site 2); Phase 8B row contains both files (site 3);
  `grep -n 'Protocol-archetype playbook' plugins/sui-ai/agents/sui-move-auditor.md` line contains
  `perps` (site 4); `grep -n 'Sui-native pitfalls)' CLAUDE.md` line contains `perps` (site 5);
  and `grep -rn 'vaults/AMM/lending/staking\|vault / AMM / lending / staking\|lending, staking, Sui-native' plugins CLAUDE.md`
  returns zero lines (no stale enumeration).
- `claude_md_mentions_fixtures_and_sources`: `grep -c 'tests/fixtures' CLAUDE.md` ≥ 1 and
  `grep -c 'docs/exploit-sources.md' CLAUDE.md` ≥ 1.
- `bump_commit_subject_names_version`: `git log --format=%s <base>..HEAD -- plugins/sui-ai/.claude-plugin/plugin.json`
  shows one commit whose subject contains `(v2.3.0)` and starts with `feat(sui-move-auditor):`.
- `bump_and_content_same_commit`: the commit that changes `plugin.json` also changes at least one
  file under `plugins/sui-ai/agents/`.
- `non_plugin_commits_do_not_bump`: every commit touching only `docs/`, `tests/`, `CLAUDE.md`
  leaves `plugin.json` unchanged.
- `branch_prefix`: `git rev-parse --abbrev-ref HEAD` matches `^(feature|bugfix|hotfix|chore)/`.
- `pr_exists_to_main_with_rationale_table`: `gh pr view --json baseRefName,body` shows
  `baseRefName == main` and the body contains "Audit-behaviour rationale" and a row for each of
  C3, C6, C7, C8, C9, C11, C12, C19, and "perps".

### Manual

- Install the plugin from the branch in a fresh Claude Code session and confirm the agent
  surfaces as `sui-ai:sui-move-auditor` and lists seven companion files when globbing
  `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/*.md` (CLAUDE.md's "testing a change" step).

### Acceptance Criteria

- [ ] `plugin.json` version is `2.3.0`, bumped in the same commit as plugin content, with a
      `feat(sui-move-auditor): … (v2.3.0)` subject (REQ-REL-001, REQ-REL-011, REQ-REL-012).
- [ ] New playbook listed in the companion table with a load-when condition; every companion
      file mention in agent content (table, 8B list, in-text) uses the full
      `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md` form — existing rows rewritten,
      `no_bare_companion_mention` returns nothing; no relative/repo paths under `plugins/`
      (REQ-REL-002, REQ-REL-003, operator decision 9).
- [ ] `sui-native-pitfalls.md` companion row's load condition names oracle / third-party
      price-object consumption; CHK-C7-4 sits in driver 7.2 (REQ-REL-013).
- [ ] All new content under `plugins/sui-ai/`; no sibling plugin dir; no `agents`/`commands`
      field (REQ-REL-004).
- [ ] Both manifests parse; `marketplace.json` byte-identical (REQ-REL-005, REQ-REL-006).
- [ ] All five enumeration sites updated; stale-enumeration grep returns nothing (REQ-REL-008).
- [ ] `CLAUDE.md` mentions `tests/fixtures/` and `docs/exploit-sources.md` and the fixture build
      command (REQ-REL-008 layout notes).
- [ ] Branch has a compliant prefix; PR targets `main`; PR body follows the six-section contract
      with the per-class rationale table (REQ-REL-009, REQ-REL-010).
- [ ] Every check is placed per the landing-spot tables in `coverage-checks.md` /
      `perps-playbook.md`; non-matching targets load no new playbook (REQ-REL-013).
- [ ] No fixture-only or docs-only commit changes `plugin.json`.
