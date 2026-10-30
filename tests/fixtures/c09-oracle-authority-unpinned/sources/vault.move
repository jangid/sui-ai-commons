// Fixture c09-oracle-authority-unpinned: an oracle-priced vault that reads a third-party
// aggregator stand-in without pinning its object id, queue or authority, accepts any single
// update with no per-update move bound, lets deposit and withdraw be priced by the same feed
// with no cooldown, and accepts signed keeper reports on signer identity alone. Those four
// omissions are the ONLY deviations from the auditor's guidance. Never deploy.
module c09_oracle_authority_unpinned::vault;

use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::{Self, Coin};
use sui::ed25519;

/// Price scale: 1.0 == 10^9.
const PRICE_SCALE: u128 = 1_000_000_000;
/// Consumer-side staleness bound (the one oracle control this module does have).
const MAX_STALENESS_MS: u64 = 60_000;

const ENotAuthority: u64 = 0;
const EStalePrice: u64 = 1;
const EBadSignature: u64 = 2;
const EZeroAmount: u64 = 3;

// ---------------------------------------------------------------------------------------------
// Third-party aggregator stand-in (Switchboard-shaped; same field roles). In a real deployment
// this lives in the oracle package; it is inlined so the fixture builds in isolation.
// ---------------------------------------------------------------------------------------------

/// A price aggregator with a mutable `authority` and `queue`, and a registered keeper key.
public struct Aggregator has key {
    id: UID,
    authority: address,
    queue: ID,
    keeper_pubkey: vector<u8>,
    price: u64,
    timestamp_ms: u64,
}

public fun create_aggregator(queue: ID, keeper_pubkey: vector<u8>, price: u64, clock: &Clock, ctx: &mut TxContext) {
    transfer::share_object(Aggregator {
        id: object::new(ctx),
        authority: ctx.sender(),
        queue,
        keeper_pubkey,
        price,
        timestamp_ms: clock.timestamp_ms(),
    });
}

/// Authority rotation: the surface a compromised authority (or signer set) uses.
public fun set_authority(agg: &mut Aggregator, new_authority: address, ctx: &TxContext) {
    assert!(ctx.sender() == agg.authority, ENotAuthority);
    agg.authority = new_authority;
}

public fun set_queue(agg: &mut Aggregator, queue: ID, ctx: &TxContext) {
    assert!(ctx.sender() == agg.authority, ENotAuthority);
    agg.queue = queue;
}

public fun set_keeper(agg: &mut Aggregator, keeper_pubkey: vector<u8>, ctx: &TxContext) {
    assert!(ctx.sender() == agg.authority, ENotAuthority);
    agg.keeper_pubkey = keeper_pubkey;
}

/// CHK-C9-2 candidate: one sample from one writer sets the price, and the move from the previous
/// value is unbounded (a 100x jump in a single update is accepted).
public fun push_price(agg: &mut Aggregator, price: u64, clock: &Clock, ctx: &TxContext) {
    assert!(ctx.sender() == agg.authority, ENotAuthority);
    agg.price = price;
    agg.timestamp_ms = clock.timestamp_ms();
}

/// CHK-C9-4 candidate: a signed keeper report is accepted on signer identity alone — the
/// signature over `bcs(price)` is verified, the value is not checked for plausibility against
/// the previous price or a second feed.
public fun submit_report(agg: &mut Aggregator, price: u64, signature: vector<u8>, clock: &Clock) {
    let message = std::bcs::to_bytes(&price);
    assert!(ed25519::ed25519_verify(&signature, &agg.keeper_pubkey, &message), EBadSignature);
    agg.price = price;
    agg.timestamp_ms = clock.timestamp_ms();
}

// ---------------------------------------------------------------------------------------------
// Consumer
// ---------------------------------------------------------------------------------------------

/// Oracle-priced vault. CHK-C9-1 candidate: no `expected_aggregator`, `expected_queue` or
/// `expected_authority` field exists, so any `Aggregator` object satisfies `deposit`/`withdraw`.
public struct Vault<phantom T> has key {
    id: UID,
    assets: Balance<T>,
    total_shares: u64,
}

/// Share receipt; one share == one price-scaled value unit at the time of deposit.
public struct Shares<phantom T> has key, store {
    id: UID,
    amount: u64,
}

public fun create_vault<T>(ctx: &mut TxContext) {
    transfer::share_object(Vault<T> { id: object::new(ctx), assets: balance::zero(), total_shares: 0 });
}

/// The only read path. Staleness is checked; `object::id(agg)`, `agg.queue` and `agg.authority`
/// are not compared with anything (CHK-C9-1), and no min-sample / move bound is asserted.
fun read_price(agg: &Aggregator, clock: &Clock): u128 {
    assert!(clock.timestamp_ms() - agg.timestamp_ms <= MAX_STALENESS_MS, EStalePrice);
    agg.price as u128
}

/// CHK-C9-3 candidate (with `withdraw`): shares are minted at the current feed price with no
/// cooldown, so deposit -> price change -> withdraw inside one staleness window extracts value.
public fun deposit<T>(vault: &mut Vault<T>, agg: &Aggregator, deposit: Coin<T>, clock: &Clock, ctx: &mut TxContext): Shares<T> {
    let amount = deposit.value();
    assert!(amount > 0, EZeroAmount);
    let shares = ((amount as u128) * read_price(agg, clock) / PRICE_SCALE) as u64;
    vault.total_shares = vault.total_shares + shares;
    vault.assets.join(deposit.into_balance());
    Shares { id: object::new(ctx), amount: shares }
}

/// Redeems shares at the current feed price, priced by the same unpinned feed as `deposit`.
public fun withdraw<T>(vault: &mut Vault<T>, agg: &Aggregator, shares: Shares<T>, clock: &Clock, ctx: &mut TxContext): Coin<T> {
    let Shares { id, amount } = shares;
    id.delete();
    let tokens = ((amount as u128) * PRICE_SCALE / read_price(agg, clock)) as u64;
    vault.total_shares = vault.total_shares - amount;
    coin::take(&mut vault.assets, tokens, ctx)
}

public fun total_shares<T>(vault: &Vault<T>): u64 {
    vault.total_shares
}
