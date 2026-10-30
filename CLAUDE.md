# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code **plugin marketplace** (`jangid/sui-ai-commons`) that ships a single umbrella plugin, `sui-ai`, for Sui development. There is no application code, build system, or test suite: the content is Markdown agent definitions plus two JSON manifests. The one exception is `tests/fixtures/` — compile-only acceptance fixtures for auditor checks (minimal vulnerable Sui Move packages, one per gap class, built with `sui move build`); they are not a test suite of the plugin and never bump its version. "Testing" a change means installing the plugin in a Claude Code session pointed at a Sui Move project and running the agent.

## Commands

There is no build, lint, or test step. The relevant operations are:

```bash
# Validate the two manifests parse
python3 -m json.tool .claude-plugin/marketplace.json
python3 -m json.tool plugins/sui-ai/.claude-plugin/plugin.json

# Build every acceptance fixture under tests/fixtures/ (compile-only; exit 0 = all clean,
# any build failure or warning/error line in any fixture fails the loop)
rc=0; for d in tests/fixtures/*/; do out=$(cd "$d" && sui move build 2>&1) || rc=1; grep -qiE '^(warning|error)' <<<"$out" && rc=1; done; exit $rc

# Install / exercise the plugin from any Claude Code session (see README)
/plugin marketplace add jangid/sui-ai-commons
/plugin install sui-ai@sui-ai-commons
```

Then invoke `sui-ai:sui-move-auditor` from a session whose cwd is the Sui Move project under audit.

## Layout and how the pieces connect

```
.claude-plugin/marketplace.json        # marketplace: lists the one plugin + append-only `renames` map
plugins/sui-ai/.claude-plugin/plugin.json   # umbrella plugin manifest: name, VERSION, description
plugins/sui-ai/agents/sui-move-auditor.md   # the agent "driver" (frontmatter + 11-phase audit procedure)
plugins/sui-ai/agents/sui-move-auditor/*.md # companion "playbooks" the driver loads on demand
docs/exploit-sources.md                # ranked exploit/advisory sources + rerun procedure for the coverage refresh
tests/fixtures/<class-slug>/           # compile-only vulnerable Move fixtures, one per auditor gap class
```

- **Driver + playbooks.** `sui-move-auditor.md` is the agent definition Claude Code loads. It is structured as sequential phases (context gathering, actor/threat model, fund security, spec-to-code, accounting invariants, Sui Move checklist, structural attacks, archetype playbooks, severity report, testing, scorecard) followed by a report template. Deep domain content lives in the companion directory and is pulled in by the driver's "COMPANION REFERENCES" table only when the audit target matches (vaults, AMM, lending, perps/margin, staking, Sui-native pitfalls). `verification-and-false-positives.md` is the exception: the driver always loads it before finalizing findings, because it holds the evidence gates and confidence tiers that cap severity.
- **Companion references must use `${CLAUDE_PLUGIN_ROOT}`.** The installed plugin is a cached copy, so the driver addresses its playbooks as `${CLAUDE_PLUGIN_ROOT}/agents/sui-move-auditor/<file>.md`, never by relative or repo path. Keep this pattern for any new agent with a companion dir.
- **Namespacing.** Everything in the umbrella surfaces as `sui-ai:<component>`. New components of any type go inside `plugins/sui-ai/`, never as a sibling `plugins/<name>/`.

## Rules that are easy to miss

- **Bump `version` in `plugins/sui-ai/.claude-plugin/plugin.json` on any content change** (agent text, future skills, future tools). Plugin updates only propagate to installed users on a version change; without the bump they stay on stale content indefinitely. Mention the new version in the commit subject, as past commits do (e.g. `feat(sui-move-auditor): ... (v2.2.0)`).
- **`renames` in `marketplace.json` is append-only history.** Never prune it; a future rename extends the chain (`sui-move-auditor` → `open-agents` → `sui-ai`).
- **Never create repos named `AlphaFiTech/open-agents` or `AlphaFiTech/sui-ai-commons`.** Doing so kills GitHub's redirects that keep old links and legacy marketplace registrations working.
- **Future skills go in `plugins/sui-ai/skills/<name>/SKILL.md`; future tools are `.mcp.json` or `bin/` at the plugin root.** Do not use `commands/`. Do not add `agents`/`commands` fields to `plugin.json`: those *replace* the default directory scan, whereas `skills` only *adds* to it.
- **Branch and PR workflow.** `main` takes changes via pull request only. Branches use a `feature/`, `bugfix/`, `hotfix/`, or `chore/` prefix. Changes to audit methodology should explain the audit-behavior rationale in the PR description.

## Editing the auditor

The auditor's content is tuned against real findings and deliberately balances a zero-trust posture with false-positive discipline. When adding a check, place it in the phase or playbook where it belongs, keep the "load when" table in the driver in sync if you add a playbook, and prefer generalized patterns over one-off protocol specifics. The driver's "OPERATING PRINCIPLES" (absence rule, enumeration-completeness gate, candidate ≠ finding, twin-function rule) are the lens every new check should fit.
