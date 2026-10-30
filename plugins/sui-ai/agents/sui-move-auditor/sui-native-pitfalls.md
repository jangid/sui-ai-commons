# Playbook — Sui-Native Pitfalls

Load for any audit — these are platform-level hazards that source-level DeFi checklists miss.
Several have permanent-brick or silent-auth-bypass failure modes with no EVM analogue.

## On-chain randomness (`sui::random`)

- **Test-and-abort / gas-refund lottery.** An `entry` fn consuming `sui::random` (`0x8`) that
  returns/emits/branches on the roll *before* the irreversible consequence lands lets a PTB read
  the outcome and `abort` when unfavorable, retrying until it wins. Trace each
  `random::generate_*` value forward to its use site: the payout/mint must be irreversible within
  the same call, and nothing derived from the roll may be observable-then-abortable. **Critical**
  for lotteries/loot boxes/raffles.
- **Predictable pseudo-randomness.** `tx_context::digest`, `object::uid_to_bytes`, `epoch`, and
  `epoch_timestamp_ms` are all deterministic/known pre-execution — an attacker simulates locally
  and submits only winning txns. The only safe source is `sui::random::Random` (VRF, v1.22+).
  Grep those four APIs feeding any selection/winner/shuffle/rarity logic.
- `sui::random` in a `public` (not `entry`) function is rejected by the framework — relevant only
  as a won't-compile flag during incomplete/source review.

## Signature verification & replay

- **Unchecked verify return value.** `ed25519_verify` / `ecdsa_*` returns `bool`; if the return
  is not `assert!`-ed, *every* signature passes — silent auth bypass. **Critical.**
- **secp256k1 malleability as a replay key.** Raw `(r, s)` signature bytes used as a
  replay-prevention `Table` key are bypassed by resubmitting `(r, n−s)` — different bytes, same
  signer. The replay key must be the message hash, not signature bytes (ed25519 strict-mode is
  non-malleable).
- **Missing domain separation / chain-id binding.** A signed message omitting chain id + this
  package/contract address replays across testnet/mainnet or sibling deployments. Deserialize the
  signed payload and confirm both are inside it.
- **Nonce replay.** Verified signature with no per-signer nonce consumed / no used-message-hash
  marker → the same authorization executes repeatedly.
- **Missing outcome params in the signed message.** If `recipient` (or amount, deadline) is a
  call argument but *not* inside the signed bytes, the submitter redirects funds while the
  signature stays valid. List every outcome-affecting param and confirm each is in the payload;
  verify BCS field order matches between signer and verifier.
- **No expiration.** Absent a `deadline`/`expires_at` field asserted against `clock`, the
  authorization is lifetime and survives whitelist/KYC revocation.
- **Signatures validated against live mutable policy, not signing-time policy.** If threshold /
  signer-set is read from admin-mutable state rather than snapshotted into the signed message, a
  deliberately-not-executed 2-of-3 request becomes valid after a routine threshold-lowering, with
  no fresh approval. Bind a monotonic `signer_policy_nonce` (bumped on every signer/threshold
  mutation) into the signed message. *Distinct from nonce replay — the request can be unused yet
  mis-validated.*

## Cross-chain / bridge / ZK

- **Recipient semantic mismatch (address vs object ID).** A source chain that locks/burns on any
  nonzero `bytes32` recipient, while the Move destination parses it as an `address` and aborts if
  the account/object doesn't exist, strands funds: locked on source, VAA never claimable. Prove
  source, docs/UI, and Move destination interpret the recipient bytes as the same identity type;
  confirm a refund/rescue path.
- **Abort-after-finality lock.** Any destination abort past the finality point (unsupported type,
  denylist, missing policy, `EAccountNotFound`) makes a valid message permanently unclaimable.
  Enumerate every such abort; require a recovery path.
- **Fake bridge package object.** A VAA/attestation object accepted by type-name only is spoofed
  by deploying a homonymous-type package. Verify the object's *originating package address*, not
  just struct layout; validate guardian-set-index currency and emitter chain/address.
- **Verifier quorum of independent operators.** Enumerate every attestation / guardian / DVN /
  verifier set that authorises a message (N found / M analysed; grep
  `threshold|quorum|guardian|verifier|signers`). Each set must have size ≥ 2 and threshold ≥ 2
  *independent* operators. A 1-of-1 configuration is no lower than High once the two-gate check
  passes (the set authorises value-moving messages; the value reachable with one key is bounded),
  regardless of operator reputation — reputation is `[ZD-DOC]`-grade and cannot dismiss. Threshold
  constant seen but path not traced ⇒ Medium. Not a finding when the 1-of-1 set authorises only
  non-value-moving metadata, or the consumer verifies the config against a registry enforcing ≥ 2.
- **Replay protection beyond a nonce.** Uniqueness must be tied to the full message content — the
  hash of the signed payload stored as a nullifier — not a nonce or sequence number alone; a
  stale sequence number must not let a validly signed packet be replayed or a fabricated one be
  accepted. Grep `nonce|sequence|processed|consumed_hash`; a bridge receive path that checks only
  a monotonic nonce is the candidate (pattern-only ⇒ max Medium). This is the bridge case of
  **Nonce replay** above — apply that bullet's used-message-hash discipline here rather than
  re-deriving it.
- **Refund never exceeds deposit; failed callbacks are inert.** Every refund / deposit-resolution
  path must pay ≤ the amount deposited, and a failed or resource-exhausted callback (abort,
  child-object cap, event-size cap) must not leave a claim in an authorisable state. Enumerate the
  refund / resolve / cancel entry points (grep `refund|resolve|cancel_deposit|release`; N/M in the
  report); absence of a `≤ deposited` bound, or of a terminal-state write before the external leg,
  is a candidate (pattern-only ⇒ max Medium). See **Hard platform limits** below for the
  resource-exhaustion mechanism.
- **Bridged-token `TreasuryCap` custody.** The mint cap for a wrapped `Coin<BridgedType>` must be
  held exclusively by the bridge; a shared object wrapping it without gating = anyone mints.
- **ZK nullifier not enforced.** Proof verified but no on-chain nullifier `Table` checked/stored →
  the same proof replays as multiple votes/claims. Require `assert!(!contains(nullifiers, n))`
  before accept + insert after; nullifier derived from a private input, not submitter-controlled
  public input; table is shared, not owned.

## Oracle integrations (Pyth / Switchboard / custom feeds)

Applies when the target reads any price object it does not itself produce. Pattern-only
candidates here are `needs_review` ⇒ max Medium.

- **Authority of consumed oracle objects.** Enumerate every third-party price object type the
  target reads (N found / M analysed; grep `PriceInfoObject|Aggregator|PriceFeed|price_oracle`).
  For each, (i) read the oracle package's source to determine who can mutate the object's
  authority / signer set / queue, and (ii) verify the target pins the expected object identity
  and, where the type has one, the expected authority, in *every* read path — one unpinned read
  path is a candidate (absence rule). `likely` requires the oracle source read (`[ZD-PROD-SOURCE]`);
  without it the finding stays `needs_review`. Do not report a Pyth consumer for lacking an
  authority pin (none exists) — only for a missing feed-ID, package, staleness or confidence check.

| Provider object | Who can change what feeds it (source read 2026-10-30) | Consumer must pin | Authority check? |
|---|---|---|---|
| Pyth `PriceInfoObject` | No per-object mutable authority: updates enter only through the Pyth package's single-feed update path, which consumes a hot potato produced from a Wormhole-verified VAA whose emitter must pass the governance-controlled data-source check (`pyth.move`, `[ZD-PROD-SOURCE]`). | The **feed identity** — `price_info::get_price_identifier(...)` equals the expected feed ID — and the object's type originates from the canonical Pyth package address. The update path matches the identifier between update and object but does not check the object against the registry, so a homonymous or attacker-created object is the consumer's problem. | **No** — there is no authority to pin. Require a staleness check (`get_price_no_older_than`; its `abs_diff` treats a future timestamp as age) and a confidence-interval check instead. |
| Switchboard On-Demand `Aggregator` | Per-feed `authority: address` and `queue: ID` fields (readers `authority()`, `queue()`, `has_authority()`). `set_authority` / `set_configs` are `public(package)` and reachable only via `actions/aggregator/aggregator_set_authority_action.move` and `aggregator_set_configs_action.move`, whose `validate` asserts `has_authority` (S-1, source read 2026-10-30, `[ZD-PROD-SOURCE]`). Oracle responses are accepted when signed by keys registered in the queue. `current_result()` returns the stored `CurrentResult` with **no** age gate. | Aggregator `object::id` **and** the expected `queue` ID (canonical mainnet queue) **and** the expected `authority`; consumer-side assertions on `min_sample_size`, `max_staleness_seconds`, `max_variance`, and its own age check of `CurrentResult` `timestamp_ms()` (also `min_timestamp_ms`, `stdev`, `range`) against `Clock`. | **Yes** — a mutable authority / queue is exactly the surface used to push a live feed ~100x off market (Full Sail, Virtue). |
| Custom / in-house feed object | Read the module: find every function that writes `price`, `authority`, `signers`, `threshold`. | Object ID + every writer capability-gated, with the cap holder enumerated in Phase 2. | Yes. |

- **Minimum oracle count and per-update move bound.** The target must require a minimum count /
  consensus of independent inputs **and** bound the maximum price move per update unless a
  second independent feed agrees (grep `min_sources|min_responses|max_deviation|max_change`).
  Both absent = candidate; one absent = candidate naming which. Several feeds drawn from one
  oracle network are one input, not consensus. Not a finding when the aggregator's own
  `min_sample_size` is read and asserted by the consumer — that counts as the minimum-count
  control.
- **Oracle-priced round trip within one staleness window.** Deposit → price change → withdraw
  inside one staleness window must not extract value: the required control is a deposit/withdraw
  cooldown or a cumulative NAV-deviation circuit breaker that applies to oracle-priced deposits
  and redemptions, not only harvests (generalizing the driver's 7.2 cumulative NAV breaker). Grep
  `cooldown|lock_until|nav_deviation|circuit_breaker` in the deposit and redeem paths; absence is
  a candidate. High requires a concrete sequence with the window length and the price move needed.
- **Signed keeper reports carry a plausibility bound.** When prices arrive as signed keeper /
  relayer payloads verified on-chain (grep `ed25519_verify|ecdsa|verify_signature` near a price
  write), acceptance must check a plausibility bound on the value — deviation from the previous
  value or from a second feed — not signer identity alone. Enumerate every signed-price entry
  point (N/M in the report); a path that verifies the signer and writes the value unbounded is
  the candidate (pattern-only ⇒ max Medium). Distinct from **Signatures validated against live
  mutable policy** above: that bullet is about the signer set, this one about the payload value.

## PTB deliverability & production reachability

The platform's transfer/ability rules, not the source text, decide whether a flow is usable in a
real PTB. Verify deliverability against those rules — and verify every proposed fix compiles.

- **`key`-only objects returned by value are undeliverable.** A struct with `key` but not `store`
  cannot be moved by the PTB `TransferObjects` command — a public function returning one by value
  leaves the caller no legal way to deliver it. The fix shape is self-custody in the callee
  (`transfer::transfer(obj, ctx.sender())`-style); never a caller-suppliable recipient parameter
  for an authority object, which converts a deliverability bug into authority redirection.
- **Non-`#[test_only]` constructor/destructor per publicly consumed struct.** For every
  hot-potato/capability struct consumed or returned by a public entry point, a production
  constructor/destructor must exist *and be reachable through the integrator-facing facade*. A
  flow whose only builders are `#[test_only]` is inert in production while the whole test suite
  stays green — tests enter through backdoors that never ship.
- **Hot-potato completion functions must not be publicly callable** when public completion lets
  anyone burn a pending action without performing the intended delivery — completion belongs at
  `public(package)`, invoked only by the module that verified the work.
- **`dynamic_object_field` values require `key + store`.** A `key`-only object cannot be attached
  as a dynamic object field — a fix that "just stores it under the parent" will not compile.
- **`transfer::transfer` is module-restricted.** It works only on types defined in the calling
  module, so a generic `redeem<T>` transferring foreign `T` cannot compile. Verify every proposed
  fix **by compile probe, not abstract reasoning** — ability and visibility rules routinely
  invalidate fixes that read fine on paper.
- **Non-drop values must be consumable in a real PTB.** A public function returning a non-drop
  value (e.g. an `Option<T>` holding a resource) with no PTB-legal consumer strands the value and
  aborts the transaction — trace every non-drop return to a callable consumer.

## Module boundaries & visibility

- **Cross-module writes need an access point in the defining module.** Struct fields can only be
  mutated, and resources minted or transferred, where they are defined — a fix that has module B
  directly touching module A's internals cannot compile. The correct shape is a
  `public(package)` access point added in the *defining* module.
- **Two-way `use` cycles are infeasible.** The compiler rejects dependency cycles outright —
  reject any proposed fix that introduces one, and verify fix proposals by compile probe rather
  than by reasoning about what "should" work.
- **Externally-depended-on accessors must exist at the required visibility.** Walk the
  integration surface (SDKs, sibling packages, documented integrators) and confirm every accessor
  they rely on is `public` — merely `public(package)` or absent breaks integrators silently at
  *their* compile time, not the protocol's.

## Hard platform limits (non-gas, permanent-brick)

- **Per-transaction dynamic-field child-object cache ceiling.** The object runtime caps the
  number of *distinct* dynamic-field children loaded per transaction (default 1,000); the 1,001st
  aborts with `MEMORY_LIMIT_EXCEEDED`. Three traps: the budget is cumulative across *all* PTB
  commands (not per-command), it is not a gas limit (raising gas does nothing; gas headroom is
  not evidence of safety), and `sui move test` does *not* enforce it (green tests prove nothing —
  only a node dry-run at projected scale does). Every atomic multi-entity op (settlement, sweep,
  epoch roll, mass liquidation, migration, keeper PTB) needs a child-budget model summed across
  commands. Severity turns on resumability and whether a cheap permissionless path can mint new
  distinct keys to inflate the count.
- **Object byte-size cap (~256KB).** A `vector`/`VecMap`/`VecSet` field on a `has key` struct is
  serialized *inline*; permissionless appends grow the object monotonically until *every* write to
  it aborts — a protocol constant, not a gas budget. Especially a `vector` redundant with an
  existing `Table` (pure liability, removable). Use `Table`/`Bag`/`TableVec` or events.
- Per-transaction created/transferred/deleted object-ID counts are separately capped.
- **Per-struct field-count protocol limit — surfaces only at publish.** Neither `sui move build`
  nor `sui move test` enforces it, so a struct near the limit is a latent publish-blocker for
  every future upgrade that adds a field. The real gate is a network publish dry-run; local
  build/test green is not evidence of publishability.

## Standard-object & framework misuse

- **`public(package) entry` is directly callable** — the `entry` modifier defeats package-only
  visibility, exposing "internal" admin logic. Enumerate every `public(package) entry`.
- **Sender taken as an `address` parameter** instead of `tx_context::sender(ctx)` for an
  ownership/auth decision — trivially spoofed. (A legitimate *recipient* address param is a
  distinct, lesser finding.)
- **Object-reference fields typed `address` instead of `ID`** — no compile-time guarantee it
  refers to an object; user addresses get confused with object IDs.
- **Passed-in data-bearing object not canonicity-checked.** `&Pool` / `&mut Vault` proves the
  *type*, never that this is *the* protocol instance. Any function reading reserves/prices/ratios/
  permissions from a passed-in object must assert `object::id(obj)` against a registry/allow-list/
  stored expected ID — else an attacker mints their own `Pool` with fake reserves.
- **Kiosk royalty bypass via self-purchase.** A freely-transferable `KioskOwnerCap` lets the owner
  list at price 0 and self-purchase, skipping `TransferPolicy` royalties/allowlist.
- **`Publisher` not secured post-init.** Left in the deployer EOA it lets a key-compromise spoof
  `Display` metadata, claim type ownership, or reconfigure transfer policies. Wrap in governance,
  or `package::burn_publisher` if unneeded. It stays valid across upgrades; multiple `package::
  claim` calls split authority across several `Publisher` objects.
- **Secret/PII in `event::emit` or `Display<T>` templates.** Chain storage is public; "private"
  fields are readable straight from indexers/wallets regardless of accessor visibility.
- **Two-step authority handoff.** Direct `transfer(admin_cap, addr)` with no propose→accept
  (where `accept` asserts `sender == proposed_admin`) is unrecoverable on a typo — the cap *is*
  the only key.
- **Denylist enforcement is validator-level, not Move code.** Flagging a missing denylist check in
  a regulated-coin `transfer` is a false positive (validators block sending pre-execution). The
  *real* risk is the ~24h epoch gap for *receiving* — burn-on-source/mint-on-destination can
  strand funds if the recipient is blocked between epochs.
- **Dynamic-field child-id derivation must use the correct parent UID.** A `Table`/`Bag` stored
  inside an outer struct has its *own* UID — deriving child ids from the outer struct's UID (or
  vice versa) reads and writes a different key space and silently misses every entry. Check each
  `derive_id`/child lookup against which UID actually parents the field.
- **Type-name keys need the canonical zero-padded form.** Type-name strings used as lookup keys
  must be canonicalized (zero-padded addresses); mixed canonical/non-canonical producers make one
  writer's entries invisible to the other's lookups.

## Fixed-point library specifics

- **Hidden multiply-before-divide overflow inside a helper `mul`.** `A.mul(B).div(C)` looks safe
  but `float`/`decimal`/`wad_ray` `mul` computes `(a*b)/WAD` internally and aborts *before*
  `div(C)` normalizes. Open the helper, derive its `VALUE_MAX`, prove `A*B ≤ bound` at each call,
  and build a threshold table with real token decimals (e.g. 500k USDC overflows after ~10h idle
  in a reward accrual).
- **Bit-shift silent wrapping.** `<<`/`>>` do **not** abort on overflow in Move (unlike `+ − *`) —
  `1u64 << 64 == 0`. An off-by-one in a `checked_shl` bound (`<` vs `<=`) silently corrupts
  instead of aborting. Check every shift's guard boundary and that shift amount ≤ bit width.
- **Packed-field mask width mismatch.** A getter `(v >> shift) & mask` that decodes fewer bits than
  the writer's true max (a count of 16 in a 4-bit field decodes to 0 at the power-of-two boundary)
  flips `is_empty`/`can_close` predicates. Distinguish index-max from count-max; boundary-test 0,
  1, max_index, max_count, 8, 16, 32 round-trip.
- **Narrowing casts** (u128→u64, u64→u8) need an explicit `assert!(value <= MAX_TYPE)`. Watch for
  **double scaling** — an interest index applied twice in one calculation.

## Deployed-package (bytecode) review

When the target is a published package with no matching source, disassemble it (`sui move
disassemble`) and apply the same checks; cite by module, basic-block label, instruction index.

- **Survives compilation:** abilities, visibility, `entry` markers, full signatures. **Does not:**
  constant/error-code names, local names, comments, macro sugar. OTW structs show a synthetic bool
  field.
- **`#[test_only]` is compiled out** — it cannot be grepped in a deployed package, and a leaked
  test helper ships as an unauthenticated mint/admin bypass. The *shape* is the signal: walk every
  public/entry fn whose name (`*_for_testing`, `mint_for_testing`, debug setters) or whose body
  (privileged action, no authorization) is test scaffolding. Applies to source review too.
- **`#[spec_only]` is NOT compiled out — it ships to production.** `#[test_only]`/`#[test]` are
  *built-in* attributes the standard toolchain strips; `#[spec_only]` is not built-in at all — it is
  meaningful **only to the `sui-prover` toolchain**, and `sui move build` / `sui client publish` do
  **not** run the prover. The base compiler treats it as an *unknown attribute*
  (`warning[W02018]: Unknown attribute 'spec_only'. Custom attributes must be wrapped in 'ext'`) and
  compiles the annotated function into the published bytecode unchanged — `#[ext(...)]` wrapping only
  silences that warning; no custom attribute ever strips code. Verified on sui 1.76.1: a
  `#[spec_only] public fun` verifier helper disassembles out of the deployed module as a live
  `public` function. Because it visually rhymes with `#[test_only]`, developers assume the same
  "stripped in prod" guarantee — so a verifier-only helper written to drain/mint/bypass
  authorization for proof purposes ships as a live, usually public, unauthenticated function (the
  publicly disclosed "$300K back door" class, pika/@pikapikasui, 2026-08-19).
  Detection: grep `#[spec_only]` and any `use prover::` imports — ANY `#[spec_only]` on a function/module is a red
  flag, and a privileged unauthenticated body (drain/mint/set-admin/supply-mut) marked `#[spec_only]`
  is **CRITICAL**; an `unknown attribute` (W02018) warning on a security-relevant item is the tell
  that the marker is inert, so treat it as a finding, not noise (`warnings = "allow"` or an un-gated
  build hides it entirely); and unlike `#[test_only]`, spec-only code IS present in deployed
  bytecode, so walk public/entry fns for prover-helper shapes (`*_spec`, `spec_*`, `prove`, `ghost`,
  `axiom`) with the same suspicion as test-helper shapes. Correct remediation keeps prover specs in a
  separate spec-only module/package that is never published (or a build step enforcing the
  separation) — never the attribute alone.
- **Guard-completeness idiom:** verify an authorization guard is a 3-part opcode sequence (push
  field/getter → `Eq/Lt/Gt` → `BrFalse` to `LdConst` + `Abort`) present on *every* basic block
  reaching the privileged `Call`. A guard elsewhere in the module does not count.
- **Verify deployed bytecode matches reviewed source**, and prefer MVR / pinned `Move.lock`
  revisions over floating git deps (resists named-address hijacking).
