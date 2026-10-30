// Fixture c07-thin-collateral-recursive-borrow: a single-asset lending market whose collateral
// listing has no supply or borrow cap, whose `supply` and `borrow` take the same `Coin<T>` with
// no same-asset / per-tx loop bound, whose oracle adapter is one last-trade price, and whose
// `refresh_price` is permissionless with no deviation gate. Those four omissions are the ONLY
// deviations from the auditor's guidance. Never deploy.
module c07_thin_collateral_recursive_borrow::lending;

use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::{Self, Coin};

/// Basis-point denominator for `collateral_factor_bps`.
const BPS: u64 = 10_000;
/// Oracle price scale: 1.0 == 10^9 price units.
const PRICE_SCALE: u128 = 1_000_000_000;

const EUndercollateralized: u64 = 0;
const EInsufficientLiquidity: u64 = 1;
const EFactorAboveOne: u64 = 2;

/// Admin capability; the only privileged action is listing a market.
public struct AdminCap has key, store {
    id: UID,
}

/// Oracle adapter stand-in. CHK-C7-3 candidate: the market's eligibility price is whatever the
/// last reported trade printed — no TWAP, no median across sources, no per-update bound.
public struct PriceFeed has store {
    last_trade_price: u64,
    updated_at_ms: u64,
}

/// A listed collateral market. CHK-C7-1 candidate: there is no `supply_cap` and no
/// `borrow_cap` field, so a thin-liquidity asset can be supplied and borrowed without limit.
public struct Market<phantom T> has key {
    id: UID,
    reserve: Balance<T>,
    collateral_factor_bps: u64,
    feed: PriceFeed,
}

/// A user's supplied and borrowed amounts of the market asset.
public struct Account<phantom T> has key {
    id: UID,
    supplied: u64,
    borrowed: u64,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
}

/// Lists `T` as collateral. Only the collateral factor is validated; nothing bounds exposure
/// to the asset's actual on-chain liquidity depth (CHK-C7-1).
public fun list_market<T>(
    _: &AdminCap,
    collateral_factor_bps: u64,
    initial_price: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(collateral_factor_bps <= BPS, EFactorAboveOne);
    transfer::share_object(Market<T> {
        id: object::new(ctx),
        reserve: balance::zero(),
        collateral_factor_bps,
        feed: PriceFeed { last_trade_price: initial_price, updated_at_ms: clock.timestamp_ms() },
    });
}

public fun open_account<T>(ctx: &mut TxContext): Account<T> {
    Account { id: object::new(ctx), supplied: 0, borrowed: 0 }
}

/// Supplies `T` as collateral. CHK-C7-2 candidate (with `borrow`): the coin returned by
/// `borrow` can be passed straight back here in the same PTB, and nothing counts the loops
/// or snapshots per-tx exposure.
public fun supply<T>(market: &mut Market<T>, account: &mut Account<T>, deposit: Coin<T>) {
    account.supplied = account.supplied + deposit.value();
    market.reserve.join(deposit.into_balance());
}

/// Borrows `T` against supplied `T`. Eligibility is priced by `PriceFeed.last_trade_price`.
public fun borrow<T>(
    market: &mut Market<T>,
    account: &mut Account<T>,
    amount: u64,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(market.reserve.value() >= amount, EInsufficientLiquidity);
    account.borrowed = account.borrowed + amount;
    assert!(is_healthy(market, account), EUndercollateralized);
    coin::take(&mut market.reserve, amount, ctx)
}

/// CHK-C7-4 candidate: anyone may push a new price, and the new value is accepted regardless
/// of its distance from the previous one or from any second source.
public fun refresh_price<T>(market: &mut Market<T>, last_trade_price: u64, clock: &Clock) {
    market.feed.last_trade_price = last_trade_price;
    market.feed.updated_at_ms = clock.timestamp_ms();
}

/// Health in value units: supplied value scaled by the collateral factor must cover debt.
fun is_healthy<T>(market: &Market<T>, account: &Account<T>): bool {
    let price = market.feed.last_trade_price as u128;
    let supplied_value = (account.supplied as u128) * price / PRICE_SCALE;
    let borrowed_value = (account.borrowed as u128) * price / PRICE_SCALE;
    supplied_value * (market.collateral_factor_bps as u128) / (BPS as u128) >= borrowed_value
}

public fun last_price_updated_at<T>(market: &Market<T>): u64 {
    market.feed.updated_at_ms
}
