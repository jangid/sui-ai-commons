---
last_updated: 2026-10-30
---

# Traceability Matrix

One row per requirement. `specs` fills Spec, `implement` fills Test and Implementation, `verify`
fills Verified.

| Requirement | Spec | Test | Implementation | Verified |
|-------------|------|------|----------------|----------|
| REQ-COV-001 | coverage-checks.md | style_lengths + no_incident_as_subject (manual re-read of every new CHK-*/PB-* bullet for the "candidate" / "Not a finding when" / absence wording, Chunk 3 task 6, Chunk 4 task 6, Chunk 9 task 1); fixture READMEs `## Expected finding` state candidates with confidence tiers (readme_headings_fixed) | every new CHK-*/PB-* bullet: sui-move-auditor.md §5.3a, §6.8, §6.14, §7.2, §PHASE 1 step 10; defi-lending-and-liquidation.md §Market creation & configuration validation (`needs_review` absence path), §Oracle staleness & price representability; sui-native-pitfalls.md §Oracle integrations, §Cross-chain / bridge / ZK; defi-perps-and-margin.md preamble + per-section "Not a finding when" carve-outs | pass |
| REQ-COV-002 | coverage-checks.md | preamble_states_cap (`max Medium`, perps); c9_section_and_table (`max Medium` in the oracle section); c6_floor_stated (High only with the live-legacy evidence); fixture READMEs state "severity cap Medium pattern-only" per candidate | defi-perps-and-margin.md preamble (pattern-only cap Medium); sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) cap sentence; severity-cap clauses of the C3/C6/C7/C8/C11/C12 bullets in sui-move-auditor.md §5.3a, §6.14, §6.8 and defi-lending-and-liquidation.md §Oracle staleness & price representability | pass |
| REQ-COV-003 | coverage-checks.md | catalog_rows_added | verification-and-false-positives.md §Move-specific false-positive catalog (4 rows) | pass |
| REQ-COV-004 | coverage-checks.md | no_incident_as_subject (incident names only inside parentheses across $D and $P/*.md; manual count Chunk 3 task 6 / Chunk 4 task 6, re-done in Chunk 9 task 1) | all CHK-*/PB-* bullets phrased as mechanisms with parenthetical incident names: sui-move-auditor.md §5.3a, §6.8, §6.14, §7.2; defi-lending-and-liquidation.md §Market creation & configuration validation, §Oracle staleness & price representability; sui-native-pitfalls.md §Oracle integrations, §Cross-chain / bridge / ZK; defi-perps-and-margin.md (all six sections) | pass |
| REQ-COV-005 | coverage-checks.md | per-class content checks (c3_bullets_in_5_3a, c6_three_items_in_6_14, c7_in_market_creation, c7_c8_in_oracle_staleness, c7_4_refresh_in_7_2, c9_section_and_table, c11_trigger_and_five_items, c12_three_bullets, c19_step_10, pb1..pb5), companion_table_row_present, phase_8b_row_names_both | C3 → sui-move-auditor.md §5.3a; C6 → §6.14; C11 → §6.8; CHK-C7-4 → §7.2; C19 → §PHASE 1 step 10; C7/C8 → defi-lending-and-liquidation.md §Market creation & configuration validation, §Oracle staleness & price representability; C9 → sui-native-pitfalls.md §Oracle integrations; C12 → §Cross-chain / bridge / ZK; perps/C20 → defi-perps-and-margin.md (wired via §COMPANION REFERENCES + §PHASE 8B) | pass |
| REQ-COV-006 | coverage-checks.md | c3_bullets_in_5_3a | sui-move-auditor.md §5.3a High-signal correctness greps — Raw-bits stored, signed-read | pass |
| REQ-COV-007 | coverage-checks.md | c3_bullets_in_5_3a | sui-move-auditor.md §5.3a High-signal correctness greps — Validation at the write boundary | pass |
| REQ-COV-008 | coverage-checks.md | c3_bullets_in_5_3a | sui-move-auditor.md §5.3a High-signal correctness greps — Caps compared in the consuming domain | pass |
| REQ-COV-009 | coverage-checks.md | c11_trigger_and_five_items; headings_exist_verbatim | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — trigger line | pass |
| REQ-COV-010 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — snapshot item | pass |
| REQ-COV-011 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — quorum / proposer threshold item | pass |
| REQ-COV-012 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — execution delay with veto item | pass |
| REQ-COV-013 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — allow-listed payload item | pass |
| REQ-COV-014 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — vote-token lock item | pass |
| REQ-COV-015 | coverage-checks.md | c6_three_items_in_6_14 | sui-move-auditor.md §6.14 Package Upgrade Safety — Two live writers of one accounting field | pass |
| REQ-COV-016 | coverage-checks.md | c6_three_items_in_6_14; c6_floor_stated | sui-move-auditor.md §6.14 Package Upgrade Safety — Immutability declared with a live legacy package | pass |
| REQ-COV-017 | coverage-checks.md | c6_three_items_in_6_14 | sui-move-auditor.md §6.14 Package Upgrade Safety — Legacy entry points reachable through routers/aggregators | pass |
| REQ-COV-018 | coverage-checks.md | c7_in_market_creation, c7_depth_unknown_path | defi-lending-and-liquidation.md §Market creation & configuration validation (Collateral listing quality) — Caps justified against liquidity depth | pass |
| REQ-COV-019 | coverage-checks.md | c7_in_market_creation | defi-lending-and-liquidation.md §Market creation & configuration validation (Collateral listing quality) — Recursive borrow-and-re-supply bounded | pass |
| REQ-COV-020 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Single-fill prices rejected | pass |
| REQ-COV-021 | coverage-checks.md | c7_4_refresh_in_7_2 | sui-move-auditor.md §7.2 Oracle & Price Manipulation — Permissionless NAV/AUM/price refresh | pass |
| REQ-COV-022 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Ratio feeds composed with a base feed | pass |
| REQ-COV-023 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Sanity band on feed changes | pass |
| REQ-COV-024 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Coupled cap parameters move together | pass |
| REQ-COV-025 | coverage-checks.md | c9_section_and_table; c9_driver_load_instruction | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Authority of consumed oracle objects (+ provider table); sui-move-auditor.md §7.2 Oracle & Price Manipulation — Consumed-feed authority and plausibility (load bullet) | pass |
| REQ-COV-026 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Minimum oracle count and per-update move bound | pass |
| REQ-COV-027 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Oracle-priced round trip within one staleness window | pass |
| REQ-COV-028 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Signed keeper reports carry a plausibility bound | pass |
| REQ-COV-029 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Verifier quorum of independent operators | pass |
| REQ-COV-030 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Replay protection beyond a nonce | pass |
| REQ-COV-031 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Refund never exceeds deposit; failed callbacks are inert | pass |
| REQ-COV-032 | perps-playbook.md | playbook_file_exists_in_companion_dir, load_when_opener_states_dual_load, six_fixed_headings_present_in_order, preamble_states_cap, known_good_section_present | defi-perps-and-margin.md (whole file: title, opener, preamble, six headings, known-good section) | pass |
| REQ-COV-033 | perps-playbook.md | load_when_opener_states_dual_load, no_bare_companion_mention_perps, lending_margin_content_untouched, companion_table_row_present, phase_8b_row_names_both | defi-perps-and-margin.md opener (dual-load sentence); sui-move-auditor.md §COMPANION REFERENCES (perps row + lending-row suffix) and §PHASE 8B Lending / margin row | pass |
| REQ-COV-034 | perps-playbook.md | pb1_settle_first | defi-perps-and-margin.md §Funding settlement ordering | pass |
| REQ-COV-035 | perps-playbook.md | pb2_window_named | defi-perps-and-margin.md §Funding-rate updates: permissioned or bounded | pass |
| REQ-COV-036 | perps-playbook.md | pb3_owner_not_account | defi-perps-and-margin.md §Self-trade and mark-price manipulation on thin books | pass |
| REQ-COV-037 | perps-playbook.md | pb4_transition | defi-perps-and-margin.md §Risk-parameter changes and open positions | pass |
| REQ-COV-038 | perps-playbook.md | pb5_points_to_driver | defi-perps-and-margin.md §Fees, funding and collateral deltas as signed-value sinks | pass |
| REQ-COV-039 | coverage-checks.md | c19_step_10 | sui-move-auditor.md §PHASE 1 — CONTEXT GATHERING, step 10 | pass |
| REQ-COV-040 | coverage-checks.md | every coverage-checks.md / perps-playbook.md `### Automated` content check (grep-decidable, no auditor run) | each CHK-*/PB-* at its cited file → heading (rows REQ-COV-006..039 above); landing spots per coverage-checks.md §Class inventory and perps-playbook.md §File and load trigger | pass |
| REQ-COV-041 | fixtures.md | each_fixture_builds_clean, readme_headings_fixed, readme_cites_valid_ids, index_table_complete, all_nine_fixture_dirs_exist, 31-id exactly-one check (Chunk 6: c11, c03, c06; Chunk 7: c07, c08, c09; Chunk 8: c12, c20, perps-funding) | tests/fixtures/c11-governance-capture/, tests/fixtures/c03-signed-value-reinterpretation/, tests/fixtures/c06-cross-version-state-desync/, tests/fixtures/c07-thin-collateral-recursive-borrow/, tests/fixtures/c08-oracle-ratio-feed-misconfig/, tests/fixtures/c09-oracle-authority-unpinned/, tests/fixtures/c12-bridge-single-verifier/, tests/fixtures/c20-perps-market-manipulation/, tests/fixtures/perps-funding-settlement-ordering/, tests/fixtures/README.md | pass |
| REQ-COV-042 | fixtures.md | each_fixture_builds_clean, readme_headings_fixed, readme_cites_valid_ids, index_table_complete, all_nine_fixture_dirs_exist, 31-id exactly-one check (Chunk 6: c11, c03, c06; Chunk 7: c07, c08, c09; Chunk 8: c12, c20, perps-funding) | tests/fixtures/c11-governance-capture/README.md, tests/fixtures/c03-signed-value-reinterpretation/README.md, tests/fixtures/c06-cross-version-state-desync/README.md, tests/fixtures/c07-thin-collateral-recursive-borrow/README.md, tests/fixtures/c08-oracle-ratio-feed-misconfig/README.md, tests/fixtures/c09-oracle-authority-unpinned/README.md, tests/fixtures/c12-bridge-single-verifier/README.md, tests/fixtures/c20-perps-market-manipulation/README.md, tests/fixtures/perps-funding-settlement-ordering/README.md | pass |
| REQ-REL-001 | release-wiring.md | version_is_2_3_0 (bump_commit_subject_names_version, bump_and_content_same_commit at the orchestrator commit) | plugins/sui-ai/.claude-plugin/plugin.json `version` 2.3.0 | pass |
| REQ-REL-002 | release-wiring.md | companion_table_row_present, companion_table_all_full_path, no_bare_companion_mention, plugin_root_prefix_present | sui-move-auditor.md §COMPANION REFERENCES (seven full-path rows) + §PHASE 8B + in-text mentions | pass |
| REQ-REL-003 | release-wiring.md | no_relative_or_repo_paths_in_plugin, no_bare_companion_mention | sui-move-auditor.md §COMPANION REFERENCES, §PHASE 8B, in-text `${CLAUDE_PLUGIN_ROOT}` mentions | pass |
| REQ-REL-004 | release-wiring.md | no_sibling_plugin_dir, playbook_in_companion_dir, no_agents_or_commands_field | plugins/sui-ai/agents/sui-move-auditor/defi-perps-and-margin.md placement; plugin.json (no agents/commands key) | pass |
| REQ-REL-005 | release-wiring.md | manifests_parse | plugins/sui-ai/.claude-plugin/plugin.json (version-only edit); .claude-plugin/marketplace.json (untouched) | pass |
| REQ-REL-006 | release-wiring.md | marketplace_unchanged | .claude-plugin/marketplace.json — not modified (`renames` byte-identical) | pass |
| REQ-REL-007 [Deprecated] | | | | |
| REQ-REL-008 | release-wiring.md | five_enumeration_sites_updated, claude_md_mentions_fixtures_and_sources | sui-move-auditor.md frontmatter `description`, §COMPANION REFERENCES, §PHASE 8B, §Appendix C item 8; CLAUDE.md §Layout and how the pieces connect | pass |
| REQ-REL-009 | release-wiring.md | branch_prefix, pr_exists_to_main_with_rationale_table (orchestrator / PR stage) | process — `feature/` branch + PR to `main` per release-wiring.md §Branch and PR (orchestrator-owned) | pass |
| REQ-REL-010 | release-wiring.md | pr_exists_to_main_with_rationale_table (PR stage) | PR body §Audit-behaviour rationale per check, per release-wiring.md §Branch and PR (orchestrator-owned) | pass |
| REQ-REL-011 | release-wiring.md | bump_commit_subject_names_version (orchestrator commit) | commit subject `feat(sui-move-auditor): … (v2.3.0)` on the commit carrying plugin.json (orchestrator-owned) | pass |
| REQ-REL-012 | release-wiring.md | version_is_2_3_0 | plugins/sui-ai/.claude-plugin/plugin.json — minor bump 2.2.0 → 2.3.0 (release-wiring.md §Version) | pass |
| REQ-REL-013 | release-wiring.md | sui_native_load_condition_mentions_oracle, companion_table_row_present, c7_4_refresh_in_7_2 | sui-move-auditor.md §COMPANION REFERENCES (sui-native-pitfalls row + oracle; perps row), §7.2 CHK-C7-4; landing spots per coverage-checks.md §Class inventory / perps-playbook.md §File and load trigger | pass |
| REQ-SRC-001 | exploit-sources.md | sources_file_exists_outside_plugins | docs/exploit-sources.md (repo-level file) | pass |
| REQ-SRC-002 | exploit-sources.md | every_source_has_full_field_block | docs/exploit-sources.md §Sources (ranked) | pass |
| REQ-SRC-003 | exploit-sources.md | last_checked_is_date_or_never | docs/exploit-sources.md §Sources (ranked) `Last checked` | pass |
| REQ-SRC-004 | exploit-sources.md | eleven_sources_present_in_rank_order | docs/exploit-sources.md §Sources (ranked) | pass |
| REQ-SRC-005 | exploit-sources.md | eleven_sources_present_in_rank_order, primary_set_names_three_sources_with_filter_field | docs/exploit-sources.md §Primary set, §Sources (ranked) | pass |
| REQ-SRC-006 | exploit-sources.md | retry_list_covers_unverified_sources | docs/exploit-sources.md §Retry list | pass |
| REQ-SRC-007 | exploit-sources.md | procedure_has_required_steps_in_order | docs/exploit-sources.md §Rerun procedure | pass |
| REQ-SRC-008 | exploit-sources.md | procedure_has_required_steps_in_order | docs/exploit-sources.md §Rerun procedure step 1 | pass |
| REQ-SRC-009 | exploit-sources.md | strict_after_rule_stated | docs/exploit-sources.md §Current cutoff, §Rerun procedure step 1 | pass |
| REQ-SRC-010 | exploit-sources.md | frontmatter_has_cutoff_and_spike | docs/exploit-sources.md frontmatter, §Current cutoff | pass |
| REQ-SRC-011 | exploit-sources.md | procedure_has_required_steps_in_order (`$1M`) | docs/exploit-sources.md §Rerun procedure steps 5–6 | pass |
| REQ-SRC-012 | exploit-sources.md | procedure_has_required_steps_in_order (`$10M`) | docs/exploit-sources.md §Rerun procedure step 7 | pass |
| REQ-SRC-013 | exploit-sources.md | procedure_has_required_steps_in_order (`C1–C25`) | docs/exploit-sources.md §Rerun procedure step 8 | pass |
| REQ-SRC-014 | exploit-sources.md | procedure_has_required_steps_in_order (`RS-00N`) | docs/exploit-sources.md §Rerun procedure step 10, sub-bullet 1 | pass |
| REQ-SRC-015 | exploit-sources.md | procedure_has_required_steps_in_order (`Repeatability`) | docs/exploit-sources.md §Rerun procedure step 10, sub-bullet 2 | pass |
| REQ-SRC-016 | exploit-sources.md | procedure_has_required_steps_in_order (`docs/research/index.md`) | docs/exploit-sources.md §Rerun procedure step 10, sub-bullet 3 | pass |
| REQ-SRC-017 | exploit-sources.md | procedure_has_required_steps_in_order (`untrusted`) | docs/exploit-sources.md §Rerun procedure step 2 | pass |
| REQ-SRC-018 | exploit-sources.md | no_automation_shipped | docs/exploit-sources.md §Rerun procedure (manual, preamble) | pass |
