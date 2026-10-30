---
last_updated: 2026-10-30
---

# Traceability Matrix

One row per requirement. `specs` fills Spec, `implement` fills Test and Implementation, `verify`
fills Verified.

| Requirement | Spec | Test | Implementation | Verified |
|-------------|------|------|----------------|----------|
| REQ-COV-001 | coverage-checks.md | | | |
| REQ-COV-002 | coverage-checks.md | | | |
| REQ-COV-003 | coverage-checks.md | catalog_rows_added | verification-and-false-positives.md §Move-specific false-positive catalog (4 rows) | |
| REQ-COV-004 | coverage-checks.md | | | |
| REQ-COV-005 | coverage-checks.md | per-class content checks (c3_bullets_in_5_3a, c6_three_items_in_6_14, c7_in_market_creation, c7_c8_in_oracle_staleness, c7_4_refresh_in_7_2, c9_section_and_table, c11_trigger_and_five_items, c12_three_bullets, c19_step_10, pb1..pb5), companion_table_row_present, phase_8b_row_names_both | C3 → sui-move-auditor.md §5.3a; C6 → §6.14; C11 → §6.8; CHK-C7-4 → §7.2; C19 → §PHASE 1 step 10; C7/C8 → defi-lending-and-liquidation.md §Market creation & configuration validation, §Oracle staleness & price representability; C9 → sui-native-pitfalls.md §Oracle integrations; C12 → §Cross-chain / bridge / ZK; perps/C20 → defi-perps-and-margin.md (wired via §COMPANION REFERENCES + §PHASE 8B) | |
| REQ-COV-006 | coverage-checks.md | c3_bullets_in_5_3a | sui-move-auditor.md §5.3a High-signal correctness greps — Raw-bits stored, signed-read | |
| REQ-COV-007 | coverage-checks.md | c3_bullets_in_5_3a | sui-move-auditor.md §5.3a High-signal correctness greps — Validation at the write boundary | |
| REQ-COV-008 | coverage-checks.md | c3_bullets_in_5_3a | sui-move-auditor.md §5.3a High-signal correctness greps — Caps compared in the consuming domain | |
| REQ-COV-009 | coverage-checks.md | c11_trigger_and_five_items; headings_exist_verbatim | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — trigger line | |
| REQ-COV-010 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — snapshot item | |
| REQ-COV-011 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — quorum / proposer threshold item | |
| REQ-COV-012 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — execution delay with veto item | |
| REQ-COV-013 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — allow-listed payload item | |
| REQ-COV-014 | coverage-checks.md | c11_trigger_and_five_items | sui-move-auditor.md §6.8 Governance, Voting & Weight Safety — vote-token lock item | |
| REQ-COV-015 | coverage-checks.md | c6_three_items_in_6_14 | sui-move-auditor.md §6.14 Package Upgrade Safety — Two live writers of one accounting field | |
| REQ-COV-016 | coverage-checks.md | c6_three_items_in_6_14; c6_floor_stated | sui-move-auditor.md §6.14 Package Upgrade Safety — Immutability declared with a live legacy package | |
| REQ-COV-017 | coverage-checks.md | c6_three_items_in_6_14 | sui-move-auditor.md §6.14 Package Upgrade Safety — Legacy entry points reachable through routers/aggregators | |
| REQ-COV-018 | coverage-checks.md | c7_in_market_creation, c7_depth_unknown_path | defi-lending-and-liquidation.md §Market creation & configuration validation (Collateral listing quality) — Caps justified against liquidity depth | |
| REQ-COV-019 | coverage-checks.md | c7_in_market_creation | defi-lending-and-liquidation.md §Market creation & configuration validation (Collateral listing quality) — Recursive borrow-and-re-supply bounded | |
| REQ-COV-020 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Single-fill prices rejected | |
| REQ-COV-021 | coverage-checks.md | c7_4_refresh_in_7_2 | sui-move-auditor.md §7.2 Oracle & Price Manipulation — Permissionless NAV/AUM/price refresh | |
| REQ-COV-022 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Ratio feeds composed with a base feed | |
| REQ-COV-023 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Sanity band on feed changes | |
| REQ-COV-024 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Coupled cap parameters move together | |
| REQ-COV-025 | coverage-checks.md | c9_section_and_table; c9_driver_load_instruction | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Authority of consumed oracle objects (+ provider table); sui-move-auditor.md §7.2 Oracle & Price Manipulation — Consumed-feed authority and plausibility (load bullet) | |
| REQ-COV-026 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Minimum oracle count and per-update move bound | |
| REQ-COV-027 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Oracle-priced round trip within one staleness window | |
| REQ-COV-028 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Signed keeper reports carry a plausibility bound | |
| REQ-COV-029 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Verifier quorum of independent operators | |
| REQ-COV-030 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Replay protection beyond a nonce | |
| REQ-COV-031 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Refund never exceeds deposit; failed callbacks are inert | |
| REQ-COV-032 | perps-playbook.md | playbook_file_exists_in_companion_dir, load_when_opener_states_dual_load, six_fixed_headings_present_in_order, preamble_states_cap, known_good_section_present | defi-perps-and-margin.md (whole file: title, opener, preamble, six headings, known-good section) | |
| REQ-COV-033 | perps-playbook.md | load_when_opener_states_dual_load, no_bare_companion_mention_perps, lending_margin_content_untouched, companion_table_row_present, phase_8b_row_names_both | defi-perps-and-margin.md opener (dual-load sentence); sui-move-auditor.md §COMPANION REFERENCES (perps row + lending-row suffix) and §PHASE 8B Lending / margin row | |
| REQ-COV-034 | perps-playbook.md | pb1_settle_first | defi-perps-and-margin.md §Funding settlement ordering | |
| REQ-COV-035 | perps-playbook.md | pb2_window_named | defi-perps-and-margin.md §Funding-rate updates: permissioned or bounded | |
| REQ-COV-036 | perps-playbook.md | pb3_owner_not_account | defi-perps-and-margin.md §Self-trade and mark-price manipulation on thin books | |
| REQ-COV-037 | perps-playbook.md | pb4_transition | defi-perps-and-margin.md §Risk-parameter changes and open positions | |
| REQ-COV-038 | perps-playbook.md | pb5_points_to_driver | defi-perps-and-margin.md §Fees, funding and collateral deltas as signed-value sinks | |
| REQ-COV-039 | coverage-checks.md | c19_step_10 | sui-move-auditor.md §PHASE 1 — CONTEXT GATHERING, step 10 | |
| REQ-COV-040 | coverage-checks.md | every coverage-checks.md / perps-playbook.md `### Automated` content check (grep-decidable, no auditor run) | each CHK-*/PB-* at its cited file → heading (rows REQ-COV-006..039 above); landing spots per coverage-checks.md §Class inventory and perps-playbook.md §File and load trigger | |
| REQ-COV-041 | fixtures.md | each_fixture_builds_clean, readme_headings_fixed, readme_cites_valid_ids (Chunk 6: c11, c03, c06; Chunk 7: c07, c08, c09) | tests/fixtures/c11-governance-capture/, tests/fixtures/c03-signed-value-reinterpretation/, tests/fixtures/c06-cross-version-state-desync/, tests/fixtures/c07-thin-collateral-recursive-borrow/, tests/fixtures/c08-oracle-ratio-feed-misconfig/, tests/fixtures/c09-oracle-authority-unpinned/ | |
| REQ-COV-042 | fixtures.md | readme_headings_fixed, readme_cites_valid_ids, each_fixture_builds_clean (Chunk 6: c11, c03, c06; Chunk 7: c07, c08, c09) | tests/fixtures/c11-governance-capture/README.md, tests/fixtures/c03-signed-value-reinterpretation/README.md, tests/fixtures/c06-cross-version-state-desync/README.md, tests/fixtures/c07-thin-collateral-recursive-borrow/README.md, tests/fixtures/c08-oracle-ratio-feed-misconfig/README.md, tests/fixtures/c09-oracle-authority-unpinned/README.md | |
| REQ-REL-001 | release-wiring.md | version_is_2_3_0 (bump_commit_subject_names_version, bump_and_content_same_commit at the orchestrator commit) | plugins/sui-ai/.claude-plugin/plugin.json `version` 2.3.0 | |
| REQ-REL-002 | release-wiring.md | companion_table_row_present, companion_table_all_full_path, no_bare_companion_mention, plugin_root_prefix_present | sui-move-auditor.md §COMPANION REFERENCES (seven full-path rows) + §PHASE 8B + in-text mentions | |
| REQ-REL-003 | release-wiring.md | no_relative_or_repo_paths_in_plugin, no_bare_companion_mention | sui-move-auditor.md §COMPANION REFERENCES, §PHASE 8B, in-text `${CLAUDE_PLUGIN_ROOT}` mentions | |
| REQ-REL-004 | release-wiring.md | no_sibling_plugin_dir, playbook_in_companion_dir, no_agents_or_commands_field | plugins/sui-ai/agents/sui-move-auditor/defi-perps-and-margin.md placement; plugin.json (no agents/commands key) | |
| REQ-REL-005 | release-wiring.md | manifests_parse | plugins/sui-ai/.claude-plugin/plugin.json (version-only edit); .claude-plugin/marketplace.json (untouched) | |
| REQ-REL-006 | release-wiring.md | marketplace_unchanged | .claude-plugin/marketplace.json — not modified (`renames` byte-identical) | |
| REQ-REL-007 [Deprecated] | | | | |
| REQ-REL-008 | release-wiring.md | five_enumeration_sites_updated, claude_md_mentions_fixtures_and_sources | sui-move-auditor.md frontmatter `description`, §COMPANION REFERENCES, §PHASE 8B, §Appendix C item 8; CLAUDE.md §Layout and how the pieces connect | |
| REQ-REL-009 | release-wiring.md | branch_prefix, pr_exists_to_main_with_rationale_table (orchestrator / PR stage) | process — `feature/` branch + PR to `main` per release-wiring.md §Branch and PR (orchestrator-owned) | |
| REQ-REL-010 | release-wiring.md | pr_exists_to_main_with_rationale_table (PR stage) | PR body §Audit-behaviour rationale per check, per release-wiring.md §Branch and PR (orchestrator-owned) | |
| REQ-REL-011 | release-wiring.md | bump_commit_subject_names_version (orchestrator commit) | commit subject `feat(sui-move-auditor): … (v2.3.0)` on the commit carrying plugin.json (orchestrator-owned) | |
| REQ-REL-012 | release-wiring.md | version_is_2_3_0 | plugins/sui-ai/.claude-plugin/plugin.json — minor bump 2.2.0 → 2.3.0 (release-wiring.md §Version) | |
| REQ-REL-013 | release-wiring.md | sui_native_load_condition_mentions_oracle, companion_table_row_present, c7_4_refresh_in_7_2 | sui-move-auditor.md §COMPANION REFERENCES (sui-native-pitfalls row + oracle; perps row), §7.2 CHK-C7-4; landing spots per coverage-checks.md §Class inventory / perps-playbook.md §File and load trigger | |
| REQ-SRC-001 | exploit-sources.md | sources_file_exists_outside_plugins | docs/exploit-sources.md (repo-level file) | |
| REQ-SRC-002 | exploit-sources.md | every_source_has_full_field_block | docs/exploit-sources.md §Sources (ranked) | |
| REQ-SRC-003 | exploit-sources.md | last_checked_is_date_or_never | docs/exploit-sources.md §Sources (ranked) `Last checked` | |
| REQ-SRC-004 | exploit-sources.md | eleven_sources_present_in_rank_order | docs/exploit-sources.md §Sources (ranked) | |
| REQ-SRC-005 | exploit-sources.md | eleven_sources_present_in_rank_order, primary_set_names_three_sources_with_filter_field | docs/exploit-sources.md §Primary set, §Sources (ranked) | |
| REQ-SRC-006 | exploit-sources.md | retry_list_covers_unverified_sources | docs/exploit-sources.md §Retry list | |
| REQ-SRC-007 | exploit-sources.md | procedure_has_required_steps_in_order | docs/exploit-sources.md §Rerun procedure | |
| REQ-SRC-008 | exploit-sources.md | procedure_has_required_steps_in_order | docs/exploit-sources.md §Rerun procedure step 1 | |
| REQ-SRC-009 | exploit-sources.md | strict_after_rule_stated | docs/exploit-sources.md §Current cutoff, §Rerun procedure step 1 | |
| REQ-SRC-010 | exploit-sources.md | frontmatter_has_cutoff_and_spike | docs/exploit-sources.md frontmatter, §Current cutoff | |
| REQ-SRC-011 | exploit-sources.md | procedure_has_required_steps_in_order (`$1M`) | docs/exploit-sources.md §Rerun procedure steps 5–6 | |
| REQ-SRC-012 | exploit-sources.md | procedure_has_required_steps_in_order (`$10M`) | docs/exploit-sources.md §Rerun procedure step 7 | |
| REQ-SRC-013 | exploit-sources.md | procedure_has_required_steps_in_order (`C1–C25`) | docs/exploit-sources.md §Rerun procedure step 8 | |
| REQ-SRC-014 | exploit-sources.md | procedure_has_required_steps_in_order (`RS-00N`) | docs/exploit-sources.md §Rerun procedure step 10, sub-bullet 1 | |
| REQ-SRC-015 | exploit-sources.md | procedure_has_required_steps_in_order (`Repeatability`) | docs/exploit-sources.md §Rerun procedure step 10, sub-bullet 2 | |
| REQ-SRC-016 | exploit-sources.md | procedure_has_required_steps_in_order (`docs/research/index.md`) | docs/exploit-sources.md §Rerun procedure step 10, sub-bullet 3 | |
| REQ-SRC-017 | exploit-sources.md | procedure_has_required_steps_in_order (`untrusted`) | docs/exploit-sources.md §Rerun procedure step 2 | |
| REQ-SRC-018 | exploit-sources.md | no_automation_shipped | docs/exploit-sources.md §Rerun procedure (manual, preamble) | |
