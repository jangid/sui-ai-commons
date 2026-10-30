// Fixture c06-cross-version-state-desync, module `legacy`: the first-version AMM pool whose
// `reserve_x` / `reserve_y` fields are still written from the pool's own balances after the
// `v2` module moved liquidity into a separate vault. Its public entry points carry no version
// gate. The cross-version desync is the ONLY deviation from the auditor's guidance. Never deploy.
module c06_cross_version_state_desync::legacy;

use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};

const EInsufficientOutput: u64 = 0;

/// Shared pool. `reserve_x` is the accounting field with two live writer lineages
/// (`legacy::add_liquidity` / `legacy::swap_x_for_y` here, `v2::deposit` in `v2.move`).
public struct Pool<phantom X, phantom Y> has key {
    id: UID,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
    reserve_x: u64,
    reserve_y: u64,
}

public fun create_pool<X, Y>(ctx: &mut TxContext) {
    transfer::share_object(Pool<X, Y> {
        id: object::new(ctx),
        balance_x: balance::zero(),
        balance_y: balance::zero(),
        reserve_x: 0,
        reserve_y: 0,
    });
}

/// Legacy writer of `reserve_x`: derives it from the pool's own balance.
public fun add_liquidity<X, Y>(pool: &mut Pool<X, Y>, coin_x: Coin<X>, coin_y: Coin<Y>) {
    pool.balance_x.join(coin_x.into_balance());
    pool.balance_y.join(coin_y.into_balance());
    pool.reserve_x = pool.balance_x.value();
    pool.reserve_y = pool.balance_y.value();
}

/// CHK-C6-3 candidate: a `public` legacy entry point that mutates shared state with no
/// version gate, pause flag or deprecation assert, so routers addressing the package by ID can
/// still trade against the legacy balances after `v2` is live.
public fun swap_x_for_y<X, Y>(
    pool: &mut Pool<X, Y>,
    coin_x: Coin<X>,
    min_out: u64,
    ctx: &mut TxContext,
): Coin<Y> {
    let amount_in = coin_x.value();
    let out = amount_in * pool.reserve_y / (pool.reserve_x + amount_in);
    assert!(out >= min_out, EInsufficientOutput);
    pool.balance_x.join(coin_x.into_balance());
    let out_balance = pool.balance_y.split(out);
    pool.reserve_x = pool.balance_x.value();
    pool.reserve_y = pool.balance_y.value();
    coin::from_balance(out_balance, ctx)
}

public fun reserve_x<X, Y>(pool: &Pool<X, Y>): u64 {
    pool.reserve_x
}

public fun reserve_y<X, Y>(pool: &Pool<X, Y>): u64 {
    pool.reserve_y
}

/// Package-internal setter used by `v2` to write the same field from a different source.
public(package) fun set_reserves<X, Y>(pool: &mut Pool<X, Y>, reserve_x: u64, reserve_y: u64) {
    pool.reserve_x = reserve_x;
    pool.reserve_y = reserve_y;
}
