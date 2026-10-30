// Fixture c20-perps-market-manipulation: a minimal perpetual market where the funding rate is
// writable by anyone without bounds, the matching path compares account IDs (not owners) and
// takes the mark price from the last fill, and the maintenance-margin setter never re-checks
// open positions. Those three omissions are the ONLY deviations from the auditor's guidance.
// Never deploy.
module c20_perps_market_manipulation::market;

use sui::clock::Clock;

/// Fixed-point scale for rates and basis points: 1.0 == 1_000_000.
const SCALE: u64 = 1_000_000;
const BPS: u64 = 10_000;

const ESelfMatch: u64 = 0;
const EZeroSize: u64 = 1;
const ENotLiquidatable: u64 = 2;
const EInsufficientMargin: u64 = 3;

/// Admin capability: gates market creation and risk-parameter changes.
public struct AdminCap has key, store {
    id: UID,
}

public struct Market has key {
    id: UID,
    /// PB-2 candidate field: per-interval funding rate (SCALE), written by `set_funding_rate`.
    funding_rate: u64,
    funding_longs_pay: bool,
    last_funding_ms: u64,
    /// PB-3 candidate field: settlement price, overwritten by every fill in `match`.
    mark_price: u64,
    /// PB-4 candidate field: written by `set_maintenance_margin` with no position re-check.
    maintenance_margin_bps: u64,
}

/// One trading account. `owner` is recorded but never consulted by the self-match guard.
public struct Account has key, store {
    id: UID,
    owner: address,
    size: u64,
    is_long: bool,
    margin: u64,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
}

public fun create_market(_: &AdminCap, initial_price: u64, maintenance_margin_bps: u64, clock: &Clock, ctx: &mut TxContext) {
    transfer::share_object(Market {
        id: object::new(ctx),
        funding_rate: 0,
        funding_longs_pay: true,
        last_funding_ms: clock.timestamp_ms(),
        mark_price: initial_price,
        maintenance_margin_bps,
    });
}

/// Anyone may open any number of accounts; the self-match guard in `match` compares these IDs.
public fun open_account(margin: u64, ctx: &mut TxContext): Account {
    Account { id: object::new(ctx), owner: ctx.sender(), size: 0, is_long: true, margin }
}

/// PB-2 candidate: no capability parameter, no `rate <= MAX_FUNDING_RATE` cap and no per-interval
/// change bound — an unprivileged caller sets any rate and harvests it via `settle_funding`.
public fun set_funding_rate(market: &mut Market, rate: u64, longs_pay: bool, clock: &Clock) {
    market.funding_rate = rate;
    market.funding_longs_pay = longs_pay;
    market.last_funding_ms = clock.timestamp_ms();
}

/// Applies one interval of funding to an account at the current rate (the PB-2 harvest path).
public fun settle_funding(market: &Market, acct: &mut Account) {
    let payment = acct.size * market.funding_rate / SCALE;
    if (acct.is_long == market.funding_longs_pay) {
        acct.margin = if (acct.margin > payment) { acct.margin - payment } else { 0 };
    } else {
        acct.margin = acct.margin + payment;
    };
}

/// PB-3 candidate: (a) the guard compares `object::id`s, so two accounts owned by the same
/// address pass; (b) `mark_price` is set to the raw fill price with no EMA/TWAP or deviation
/// bound against an index, so a same-block self-trade moves the settlement price.
/// (Named `match_orders` because `match` is a reserved word in Move 2024.)
public fun match_orders(market: &mut Market, taker: &mut Account, maker: &mut Account, size: u64, price: u64) {
    assert!(size > 0, EZeroSize);
    assert!(object::id(taker) != object::id(maker), ESelfMatch);
    taker.size = taker.size + size;
    taker.is_long = true;
    maker.size = maker.size + size;
    maker.is_long = false;
    market.mark_price = price;
}

/// PB-4 candidate: writes the new threshold immediately; no re-check of open positions, no
/// transition window, no bounded step — positions healthy a moment ago become liquidatable.
public fun set_maintenance_margin(_: &AdminCap, market: &mut Market, bps: u64) {
    market.maintenance_margin_bps = bps;
}

/// Liquidation sink: compares the account's margin with the notional at `mark_price` under the
/// current `maintenance_margin_bps`, then seizes the margin.
public fun liquidate(market: &Market, acct: &mut Account): u64 {
    let notional = acct.size * market.mark_price / SCALE;
    let required = notional * market.maintenance_margin_bps / BPS;
    assert!(acct.margin < required, ENotLiquidatable);
    let seized = acct.margin;
    acct.margin = 0;
    acct.size = 0;
    seized
}

/// Withdraw margin while staying above the maintenance threshold at the current mark price.
public fun remove_margin(market: &Market, acct: &mut Account, amount: u64) {
    assert!(acct.margin >= amount, EInsufficientMargin);
    acct.margin = acct.margin - amount;
    let notional = acct.size * market.mark_price / SCALE;
    assert!(acct.margin >= notional * market.maintenance_margin_bps / BPS, EInsufficientMargin);
}

public fun mark_price(market: &Market): u64 {
    market.mark_price
}

public fun owner(acct: &Account): address {
    acct.owner
}
