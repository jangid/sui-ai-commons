---
version: 2.0
status: Approved
last_updated: 2026-10-30
---

# Requirements Index

## Summary

`jangid/sui-ai-commons` ships the `sui-ai` Claude Code plugin whose `sui-move-auditor` agent
encodes known exploit classes for Sui Move contracts. Research spike RS-001 (cutoff 2026-10-30)
ranked public exploit trackers, catalogued one year of incidents, and found two root-cause classes
the auditor does not check, six it checks only partially, a missing perpetuals/margin archetype,
and one advisory context item. This requirements set covers three things: (SRC) a durable,
repo-level exploit-source list and the periodic rerun procedure that lets the operator repeat the
refresh against only new incidents; (COV) the auditor checks that must exist after the change so
every RS-001 gap class becomes citable, within the driver's evidence-gate discipline; and (REL)
the repository conventions — plugin version bump, driver companion-table wiring, placement,
manifests, branch/PR workflow — the delivery must satisfy. Requirements state what must hold, not
how checks are worded; check wording and grep seeds are for the specs and implement stages.

## Stakeholders

- Repository maintainer (operator) — owns the auditor, runs the periodic refresh, took operator
  decisions 1–8 recorded in `docs/handoff/kickoff.md` §"Operator decisions (numbered)"; every
  "(operator decision N)" citation in these files refers to that numbered list.
- RS-001 research findings (`docs/research/RS-001-exploit-coverage-refresh/findings.md`) — the
  evidence base: source table (a), incident catalog (b), gap table (c), rerun procedure (d).

## Files

| Category | File | Domain | Status | Count | Last Updated |
|----------|------|--------|--------|-------|--------------|
| Functional | functional/auditor-coverage.md | COV | Draft | 42 | 2026-10-30 |
| Functional | functional/exploit-sources.md | SRC | Draft | 18 | 2026-10-30 |
| Non-functional | non-functional/release.md | REL | Draft | 12 | 2026-10-30 |

## Domain Prefixes

Reserved prefixes to prevent collisions:

| Prefix | File | Description |
|--------|------|-------------|
| COV | functional/auditor-coverage.md | New and strengthened auditor checks derived from the RS-001 gap table (C3, C11 uncovered; C6, C7, C8, C9, C12, C20 partial; perps archetype; C19 advisory) and the content-level / fixture-level verification basis (operator decision 8) |
| REL | non-functional/release.md | Plugin versioning, driver companion-table wiring, placement, manifest integrity, branch/PR conventions |
| SRC | functional/exploit-sources.md | Durable exploit-source list at `docs/exploit-sources.md` and the periodic rerun procedure |

## Out of Scope

- Writing the check text itself, grep seeds, or playbook prose (implement stage).
- New checks for classes RS-001 marks "covered" (C1, C2, C4, C5, C10, C13, C14, C15, C16, C17
  lending side, C18, C21, C24) — operator decision 6.
- Checks for classes not applicable to source-level Move review: C22 fee-on-transfer / reserve
  sync, C23 reentrancy, C25 off-chain cryptography (TSS), token-approval abuse and EVM proxy
  mechanics. No check is added for them; instead each gets a row in the Move-specific
  false-positive catalog (the Reentrancy row already exists, the others are added) so the
  exclusion is auditable — REQ-COV-003, operator decision 5.
- Running the auditor as part of verification: compliance of coverage requirements is decided by
  the instructing text and by compiling fixtures under `tests/fixtures/` (REQ-COV-040..042,
  operator decision 8), not by observing an auditor run.
- Automating the exploit fetch (scripts, cron); the procedure is manual (kickoff; REQ-SRC-018).
- Non-security incidents (rug pulls without a code exploit, phishing of individuals, exchange
  insider theft) beyond noting their exclusion in a rerun.
- Reconciling loss figures across trackers (RS-001 open question; not needed for class-level
  gap analysis).
- Any repository other than `jangid/sui-ai-commons`; any change to `renames` in
  `.claude-plugin/marketplace.json`.
- Per-component plugin versioning (the umbrella has one version).

## Open Questions

- [needs-spike] REQ-COV-025: do consumers of Pyth price-info objects need the oracle-authority
  pinning check, or only staleness and confidence checks? The Switchboard mechanism behind Full
  Sail / Virtue is unpublished; RS-001 sketches assume a mutable aggregator authority. Confirm
  against the Switchboard and Pyth Move sources before the spec fixes the check's scope.
- BlueMove root cause is contested (overflow vs cross-version reserve desync vs insider). REQ-COV-015
  follows the desync reading; if an official post-mortem appears, the next rerun should
  re-classify (not blocking).
- Default taken without an explicit operator decision: the rerun procedure is placed inside
  `docs/exploit-sources.md` (REQ-SRC-007) rather than only referenced from RS-001 §Q4, because
  operator decision 1 names that file as the one the next run starts from. Confirm at the gate.
- Default taken: the first rerun's class taxonomy is C1–C25 from RS-001 table (c), extended by
  each later spike (REQ-SRC-013). No separate taxonomy file is required.
- Default taken (fix pass): REQ-REL-007 ("source list edits do not bump the plugin version") was
  dropped as self-satisfying — it restated REQ-SRC-001's placement rule; the ID is marked
  `[Deprecated]` in traceability and is never reused.
- Default taken (fix pass): the `<class-slug>` naming for `tests/fixtures/` directories is left to
  the specs stage; REQ-COV-042 requires each fixture README to name its class so the mapping is
  discoverable without a convention file.
- Severity floors in REQ-COV-016 and REQ-COV-029 ("no lower than High") come from RS-001's
  sketches and apply only after the evidence gates pass; confirm they are compatible with the
  confidence tiers in `verification-and-false-positives.md` when the spec is written.

## Glossary

- **Driver** — `plugins/sui-ai/agents/sui-move-auditor.md`, the agent definition with twelve
  audit phases (Phases 1–11 plus Phase 8B "Protocol archetype playbooks", which routes a target to
  its companion playbooks) and the "COMPANION REFERENCES" load-when table.
- **Playbook** — a companion file in `plugins/sui-ai/agents/sui-move-auditor/` loaded on demand
  when the target matches its archetype.
- **Class (C1–C25)** — a root-cause class from RS-001 gap table (c); "covered / partial /
  uncovered / n/a" is the coverage status against the auditor.
- **Candidate vs finding** — a pattern hit is a candidate; it becomes a finding only after the
  evidence and feasibility gates in `verification-and-false-positives.md`.
- **Pattern-only finding** — a finding supported by pattern evidence alone; capped at Medium.
- **Cutoff** — the incident date (UTC day) up to and including which a run has catalogued
  incidents; the next run keeps only incidents dated strictly after it. This run: 2026-10-30.
- **Rerun / spike `RS-00N`** — a later execution of the refresh procedure, written as a new
  research spike; earlier spikes are immutable.
- **Move-ecosystem** — Sui, Aptos, Movement, IOTA, Initia chains, or incidents labelled
  Move-language.
- **Perps / margin archetype** — perpetual futures and margin trading: positions, leverage,
  funding, margin collateral, integrator/builder fee codes.
- **Evidence gates** — the two-gate feasibility check, confidence tiers and provenance rules in
  `verification-and-false-positives.md`.
- **Absence rule / enumeration-completeness gate** — driver operating principles: a control that
  is looked for and not found is reported as a missing-control candidate; a check over a set must
  enumerate the whole set and state the count before concluding.
- **Fixture** — a minimal vulnerable Sui Move package under `tests/fixtures/<class-slug>/` that
  compiles with `sui move build` and that a check is expected to flag; the fixture-level acceptance
  evidence for a coverage requirement (REQ-COV-041).
- **Operator decision N** — entry N of `docs/handoff/kickoff.md` §"Operator decisions (numbered)".

## See Also

- [Traceability Matrix](traceability.md)
- Research: `docs/research/index.md`, `docs/research/RS-001-exploit-coverage-refresh/findings.md`
- Kickoff: `docs/handoff/kickoff.md`
- Conventions: `CLAUDE.md`, `CONTRIBUTING.md`
