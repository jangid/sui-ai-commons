# Vulnerable Move Fixtures

Dependency variant (spike S-2, Sui CLI 1.81.1, 2026-10-30): every fixture uses the **implicit**
framework dependency — no `[dependencies]` table in `Move.toml`; the CLI supplies `Sui` and
`MoveStdlib` from its own release and the committed `Move.lock` pins the resolved framework
commit (`83f11dc85d5695a57894329b005b78d75f9bb059`, `use_environment = "testnet"`). Never mix in
an explicit `Sui = { git = ... }` line; the variant is a single repository-wide decision.
