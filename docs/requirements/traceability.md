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
| REQ-COV-005 | coverage-checks.md | | | |
| REQ-COV-006 | coverage-checks.md | | | |
| REQ-COV-007 | coverage-checks.md | | | |
| REQ-COV-008 | coverage-checks.md | | | |
| REQ-COV-009 | coverage-checks.md | | | |
| REQ-COV-010 | coverage-checks.md | | | |
| REQ-COV-011 | coverage-checks.md | | | |
| REQ-COV-012 | coverage-checks.md | | | |
| REQ-COV-013 | coverage-checks.md | | | |
| REQ-COV-014 | coverage-checks.md | | | |
| REQ-COV-015 | coverage-checks.md | | | |
| REQ-COV-016 | coverage-checks.md | | | |
| REQ-COV-017 | coverage-checks.md | | | |
| REQ-COV-018 | coverage-checks.md | c7_in_market_creation, c7_depth_unknown_path | defi-lending-and-liquidation.md §Market creation & configuration validation (Collateral listing quality) — Caps justified against liquidity depth | |
| REQ-COV-019 | coverage-checks.md | c7_in_market_creation | defi-lending-and-liquidation.md §Market creation & configuration validation (Collateral listing quality) — Recursive borrow-and-re-supply bounded | |
| REQ-COV-020 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Single-fill prices rejected | |
| REQ-COV-021 | coverage-checks.md | | | |
| REQ-COV-022 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Ratio feeds composed with a base feed | |
| REQ-COV-023 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Sanity band on feed changes | |
| REQ-COV-024 | coverage-checks.md | c7_c8_in_oracle_staleness | defi-lending-and-liquidation.md §Oracle staleness & price representability — Coupled cap parameters move together | |
| REQ-COV-025 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Authority of consumed oracle objects (+ provider table) | |
| REQ-COV-026 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Minimum oracle count and per-update move bound | |
| REQ-COV-027 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Oracle-priced round trip within one staleness window | |
| REQ-COV-028 | coverage-checks.md | c9_section_and_table | sui-native-pitfalls.md §Oracle integrations (Pyth / Switchboard / custom feeds) — Signed keeper reports carry a plausibility bound | |
| REQ-COV-029 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Verifier quorum of independent operators | |
| REQ-COV-030 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Replay protection beyond a nonce | |
| REQ-COV-031 | coverage-checks.md | c12_three_bullets | sui-native-pitfalls.md §Cross-chain / bridge / ZK — Refund never exceeds deposit; failed callbacks are inert | |
| REQ-COV-032 | perps-playbook.md | playbook_file_exists_in_companion_dir, load_when_opener_states_dual_load, six_fixed_headings_present_in_order, preamble_states_cap, known_good_section_present | defi-perps-and-margin.md (whole file: title, opener, preamble, six headings, known-good section) | |
| REQ-COV-033 | perps-playbook.md | load_when_opener_states_dual_load, no_bare_companion_mention_perps, lending_margin_content_untouched (companion_table_row_present, phase_8b_row_names_both — Chunk 5) | defi-perps-and-margin.md opener (dual-load sentence); driver companion table + Phase 8B row — Chunk 5, open | |
| REQ-COV-034 | perps-playbook.md | pb1_settle_first | defi-perps-and-margin.md §Funding settlement ordering | |
| REQ-COV-035 | perps-playbook.md | pb2_window_named | defi-perps-and-margin.md §Funding-rate updates: permissioned or bounded | |
| REQ-COV-036 | perps-playbook.md | pb3_owner_not_account | defi-perps-and-margin.md §Self-trade and mark-price manipulation on thin books | |
| REQ-COV-037 | perps-playbook.md | pb4_transition | defi-perps-and-margin.md §Risk-parameter changes and open positions | |
| REQ-COV-038 | perps-playbook.md | pb5_points_to_driver | defi-perps-and-margin.md §Fees, funding and collateral deltas as signed-value sinks | |
| REQ-COV-039 | coverage-checks.md | | | |
| REQ-COV-040 | coverage-checks.md | | | |
| REQ-COV-041 | fixtures.md | | | |
| REQ-COV-042 | fixtures.md | | | |
| REQ-REL-001 | release-wiring.md | | | |
| REQ-REL-002 | release-wiring.md | | | |
| REQ-REL-003 | release-wiring.md | | | |
| REQ-REL-004 | release-wiring.md | | | |
| REQ-REL-005 | release-wiring.md | | | |
| REQ-REL-006 | release-wiring.md | | | |
| REQ-REL-007 [Deprecated] | | | | |
| REQ-REL-008 | release-wiring.md | | | |
| REQ-REL-009 | release-wiring.md | | | |
| REQ-REL-010 | release-wiring.md | | | |
| REQ-REL-011 | release-wiring.md | | | |
| REQ-REL-012 | release-wiring.md | | | |
| REQ-REL-013 | release-wiring.md | | | |
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
