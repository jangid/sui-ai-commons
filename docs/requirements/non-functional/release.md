---
domain: REL
last_updated: 2026-10-30
status: Approved
---

# Requirements: Release and Repository Conventions

## Overview

This domain captures the repository's mandatory conventions that the exploit-coverage change
must satisfy when it lands: plugin versioning, how a new companion playbook is wired into the
driver, where content may live, manifest integrity, and the branch/PR workflow. Sources:
`CLAUDE.md` ("Rules that are easy to miss", "Editing the auditor"), `CONTRIBUTING.md`
("Versioning rule (mandatory)", "Rulesets note"), and operator decisions 2 and 4 (recorded in `docs/handoff/kickoff.md` §"Operator decisions (numbered)"). These are
constraints on the delivery, not on auditor behavior; auditor behavior is in `functional/`.

## Requirements

### REQ-REL-001: Plugin version bump on any plugin content change
Any change under `plugins/sui-ai/` (driver text, any playbook, the new perps playbook) must be
accompanied by a bump of `version` in `plugins/sui-ai/.claude-plugin/plugin.json` in the same
change set, because installed users receive updates only on a version change (operator
decision 4; CONTRIBUTING.md).

### REQ-REL-002: New playbook wired into the driver's companion table
The new companion playbook must be listed in the driver's "COMPANION REFERENCES" load-when table
with a "load when" condition, and every reference to it from agent content must use the
`${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md` form (operator decision 2;
CLAUDE.md).

### REQ-REL-003: No relative or repo paths to companion files
No agent content added or modified by this cycle may address a companion file by a relative path
or a repository path; the plugin must remain self-contained under `plugins/sui-ai/` because the
installed copy is a cache that excludes traversal targets (CONTRIBUTING.md).

### REQ-REL-004: Content stays inside the umbrella plugin
All new plugin content must be placed inside `plugins/sui-ai/` (the new playbook in
`plugins/sui-ai/agents/sui-move-auditor/`); no sibling `plugins/<name>/` directory may be
created, and no `agents` or `commands` field may be added to `plugin.json` (CLAUDE.md).

### REQ-REL-005: Manifests remain valid JSON
After the change, both `.claude-plugin/marketplace.json` and
`plugins/sui-ai/.claude-plugin/plugin.json` must parse with `python3 -m json.tool`
(CLAUDE.md "Commands").

### REQ-REL-006: Renames map untouched
The change must not modify or prune the `renames` map in `.claude-plugin/marketplace.json`
(append-only history; CONTRIBUTING.md).

### REQ-REL-008: Playbook set enumerations stay in sync
Every place that enumerates the auditor's playbook set — the driver's frontmatter `description`
(currently "vaults/AMM/lending/staking"), the driver's companion-references table, the driver's
"PHASE 8B — PROTOCOL ARCHETYPE PLAYBOOKS" archetype-to-playbook list (whose "Lending / margin"
row must name both the lending and the perps playbook per REQ-COV-033), and `CLAUDE.md`'s layout
notes — must be updated to include the perps/margin playbook in the same change set, so no
enumeration is left listing a stale set. [Updated: 2026-10-30]

### REQ-REL-009: Branch prefix and PR to main
The change must be delivered on a branch whose name starts with `feature/`, `bugfix/`, `hotfix/`
or `chore/`, and must reach `main` only through a pull request (CONTRIBUTING.md "Rulesets note";
operator decision 4).

### REQ-REL-010: PR explains audit-behavior rationale
The pull request description must explain the audit-behavior rationale for each new or
strengthened check, citing the RS-001 class it addresses (CONTRIBUTING.md; CLAUDE.md "Branch
and PR workflow").

### REQ-REL-011: Version mentioned in the commit subject
The commit that bumps the plugin version should name the new version in its subject, following
the repository's existing pattern (e.g. `feat(sui-move-auditor): ... (v2.2.0)`) (CLAUDE.md).

### REQ-REL-012: Bump size reflects a new playbook
Because the change adds a new playbook and new checks, the plugin version bump should be at
least a minor bump; patch/minor/major remains the author's judgment per CONTRIBUTING.md, but a
patch bump for this change would understate it.

### REQ-REL-013: Checks placed where the target matches
Each new check must be placed in a driver phase or playbook whose load condition matches the
target that exhibits the class, so that the driver's load-on-demand model keeps non-matching
audits unchanged (CLAUDE.md "Editing the auditor"). The concrete landing spot of each check is a
specs-stage decision informed by RS-001's suggestions, except where an operator decision already
fixes it: perps and margin checks land in `defi-perps-and-margin.md` (operator decision 2), and
margin targets also keep the lending playbook (REQ-COV-033). [Updated: 2026-10-30]
