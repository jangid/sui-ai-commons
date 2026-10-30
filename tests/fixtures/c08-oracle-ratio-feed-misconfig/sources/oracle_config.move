// Fixture c08-oracle-ratio-feed-misconfig: a lending oracle configuration where an LST/base
// *ratio* feed is consumed as a USD price, `set_feed` swaps the feed with no sanity band, and the
// rate-limited growth cap's reference ratio and reference timestamp are settable separately.
// Those three omissions are the ONLY deviations from the auditor's guidance. Never deploy.
module c08_oracle_ratio_feed_misconfig::oracle_config;

use sui::clock::Clock;

/// Basis-point denominator.
const BPS: u128 = 10_000;
/// Feed value scale: 1.0 == 10^9 (so a cbETH/ETH ratio of 1.12 is stored as 1_120_000_000).
const PRICE_SCALE: u128 = 1_000_000_000;
/// Milliseconds per year, used by the growth-cap extrapolation.
const YEAR_MS: u128 = 31_536_000_000;

const EZeroPrice: u64 = 0;

/// Admin capability guarding every setter in this module.
public struct AdminCap has key, store {
    id: UID,
}

/// Oracle feed stand-in. `is_ratio` records whether the value is an exchange rate (LST/base)
/// or a USD price; CHK-C8-1 candidate: `collateral_price_usd` never looks at it.
public struct Feed has copy, drop, store {
    value: u64,
    is_ratio: bool,
    updated_at_ms: u64,
}

/// Per-collateral oracle configuration, including the CAPO-style growth-cap parameters.
public struct OracleConfig has key {
    id: UID,
    collateral_feed: Feed,
    /// Reference ratio for the growth cap. CHK-C8-3 candidate (with `snapshot_timestamp_ms`):
    /// updated by its own setter, leaving the timestamp at its old value.
    snapshot_ratio: u64,
    snapshot_timestamp_ms: u64,
    max_yearly_growth_bps: u64,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
}

/// Creates a shared configuration; the growth-cap snapshot starts coherent (ratio + timestamp
/// written together) and is desynchronised later by the separate setters.
public fun create(
    _: &AdminCap,
    feed_value: u64,
    feed_is_ratio: bool,
    max_yearly_growth_bps: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(feed_value > 0, EZeroPrice);
    let now = clock.timestamp_ms();
    transfer::share_object(OracleConfig {
        id: object::new(ctx),
        collateral_feed: Feed { value: feed_value, is_ratio: feed_is_ratio, updated_at_ms: now },
        snapshot_ratio: feed_value,
        snapshot_timestamp_ms: now,
        max_yearly_growth_bps,
    });
}

/// CHK-C8-2 candidate: replaces the feed in one step. The new value is not compared with the
/// previous value or any secondary reference, and there is no time-lock before it is live.
public fun set_feed(_: &AdminCap, cfg: &mut OracleConfig, value: u64, is_ratio: bool, clock: &Clock) {
    assert!(value > 0, EZeroPrice);
    cfg.collateral_feed = Feed { value, is_ratio, updated_at_ms: clock.timestamp_ms() };
}

/// CHK-C8-3 candidate: moves the growth-cap reference ratio but not its reference timestamp.
public fun set_snapshot_ratio(_: &AdminCap, cfg: &mut OracleConfig, ratio: u64) {
    assert!(ratio > 0, EZeroPrice);
    cfg.snapshot_ratio = ratio;
}

/// CHK-C8-3 candidate: the coupled timestamp is a separate setter rather than part of one
/// atomic snapshot update.
public fun set_snapshot_timestamp(_: &AdminCap, cfg: &mut OracleConfig, timestamp_ms: u64) {
    cfg.snapshot_timestamp_ms = timestamp_ms;
}

public fun set_max_yearly_growth(_: &AdminCap, cfg: &mut OracleConfig, bps: u64) {
    cfg.max_yearly_growth_bps = bps;
}

/// Growth-capped feed value: the reference ratio extrapolated forward at the max growth rate.
fun capped_value(cfg: &OracleConfig, clock: &Clock): u128 {
    let elapsed = (clock.timestamp_ms() - cfg.snapshot_timestamp_ms) as u128;
    let base = cfg.snapshot_ratio as u128;
    let cap = base + base * (cfg.max_yearly_growth_bps as u128) * elapsed / (BPS * YEAR_MS);
    let value = cfg.collateral_feed.value as u128;
    if (value > cap) cap else value
}

/// Health-path read. CHK-C8-1 candidate: the capped feed value is returned as a USD price
/// whether `collateral_feed.is_ratio` is true or false — a cbETH/ETH ratio of 1.12 prices
/// cbETH at $1.12 because it is never multiplied by a base/USD feed.
public fun collateral_price_usd(cfg: &OracleConfig, clock: &Clock): u128 {
    capped_value(cfg, clock)
}

/// Returns true when the position may be liquidated at the (mis)priced collateral value.
public fun is_liquidatable(
    cfg: &OracleConfig,
    collateral_amount: u64,
    debt_usd: u128,
    liquidation_threshold_bps: u64,
    clock: &Clock,
): bool {
    let collateral_usd = (collateral_amount as u128) * collateral_price_usd(cfg, clock) / PRICE_SCALE;
    collateral_usd * (liquidation_threshold_bps as u128) / BPS < debt_usd
}
