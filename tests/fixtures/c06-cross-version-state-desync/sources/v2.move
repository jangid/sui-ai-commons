// Fixture c06-cross-version-state-desync, module `v2`: the upgraded version that escrows
// liquidity in a `Vault` yet keeps writing the legacy `Pool.reserve_x` field from the vault's
// balance, prices LP mints by that shared field, and lets the admin make the package immutable
// while `legacy` still holds funds. Never deploy.
module c06_cross_version_state_desync::v2;

use c06_cross_version_state_desync::legacy::{Self, Pool};
use sui::balance::{Self, Balance};
use sui::coin::Coin;
use sui::package::{Self, UpgradeCap};

/// Admin capability; held by the deployer after `init`.
public struct AdminCap has key, store {
    id: UID,
}

/// V2 escrow for liquidity. Its balances, not the legacy pool's, back V2 pricing.
public struct Vault<phantom X, phantom Y> has key {
    id: UID,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
    lp_supply: u64,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
}

public fun create_vault<X, Y>(_: &AdminCap, ctx: &mut TxContext) {
    transfer::share_object(Vault<X, Y> {
        id: object::new(ctx),
        balance_x: balance::zero(),
        balance_y: balance::zero(),
        lp_supply: 0,
    });
}

/// CHK-C6-1 candidate: second live writer of `Pool.reserve_x`, from the VAULT balance, while
/// `legacy::add_liquidity` / `legacy::swap_x_for_y` keep writing it from the POOL balance.
/// Whichever version traded last decides the value V2 pricing reads.
public fun deposit<X, Y>(
    pool: &mut Pool<X, Y>,
    vault: &mut Vault<X, Y>,
    coin_x: Coin<X>,
    coin_y: Coin<Y>,
): u64 {
    let amount_x = coin_x.value();
    vault.balance_x.join(coin_x.into_balance());
    vault.balance_y.join(coin_y.into_balance());
    let minted = quote_mint(pool, amount_x);
    vault.lp_supply = vault.lp_supply + minted;
    legacy::set_reserves(pool, vault.balance_x.value(), vault.balance_y.value());
    minted
}

/// LP mint pricing divides by the shared `reserve_x`; after a legacy swap deflates it, a V2
/// deposit mints far more LP than it should (the BlueMove shape).
public fun quote_mint<X, Y>(pool: &Pool<X, Y>, amount_x: u64): u64 {
    let reserve_x = legacy::reserve_x(pool);
    if (reserve_x == 0) {
        amount_x
    } else {
        amount_x * amount_x / reserve_x
    }
}

/// CHK-C6-2 candidate: declares immutability (no patch path) while `legacy::Pool` still holds
/// `balance_x` / `balance_y` and `legacy::swap_x_for_y` is neither paused nor version-gated.
public fun make_immutable(_: &AdminCap, upgrade_cap: UpgradeCap) {
    package::make_immutable(upgrade_cap);
}
