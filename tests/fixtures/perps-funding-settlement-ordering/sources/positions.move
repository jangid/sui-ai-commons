// Fixture perps-funding-settlement-ordering: a minimal perpetual position module with a correct,
// keeper-gated, bounded funding accumulator whose position mutators change `size` / `margin`
// BEFORE the account's pending funding is settled. That ordering is the ONLY deviation from the
// auditor's guidance. Never deploy.
module perps_funding_settlement_ordering::positions;

use sui::clock::Clock;

/// Fixed-point scale for the funding index: 1.0 == 1_000_000.
const SCALE: u64 = 1_000_000;
/// Upper bound on the funding rate per millisecond (keeps `update_funding` a known-good setter).
const MAX_RATE_PER_MS: u64 = 10;

const EZeroAmount: u64 = 0;
const ERateAboveCap: u64 = 1;
const EInsufficientMargin: u64 = 2;

/// Keeper capability: gates funding-rate updates (PB-2 is satisfied on purpose).
public struct KeeperCap has key, store {
    id: UID,
}

public struct Market has key {
    id: UID,
    /// Global funding index (SCALE units per unit of size), monotonically increasing.
    cumulative_funding: u64,
    rate_per_ms: u64,
    last_update_ms: u64,
}

public struct Position has key {
    id: UID,
    size: u64,
    margin: u64,
    /// Index snapshot taken at the last settlement; pending funding = (global - snapshot) * size.
    funding_index_at_settle: u64,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(KeeperCap { id: object::new(ctx) }, ctx.sender());
}

public fun create_market(_: &KeeperCap, clock: &Clock, ctx: &mut TxContext) {
    transfer::share_object(Market {
        id: object::new(ctx),
        cumulative_funding: 0,
        rate_per_ms: 0,
        last_update_ms: clock.timestamp_ms(),
    });
}

/// Known-good: permissioned and bounded funding update that advances the global index.
public fun update_funding(_: &KeeperCap, market: &mut Market, rate_per_ms: u64, clock: &Clock) {
    assert!(rate_per_ms <= MAX_RATE_PER_MS, ERateAboveCap);
    let now = clock.timestamp_ms();
    let elapsed = now - market.last_update_ms;
    market.cumulative_funding = market.cumulative_funding + market.rate_per_ms * elapsed;
    market.rate_per_ms = rate_per_ms;
    market.last_update_ms = now;
}

/// Opens a position with a fresh index snapshot (nothing pending yet).
public fun open_position(market: &Market, size: u64, margin: u64, ctx: &mut TxContext): Position {
    assert!(size > 0 && margin > 0, EZeroAmount);
    Position { id: object::new(ctx), size, margin, funding_index_at_settle: market.cumulative_funding }
}

/// Settles the account's pending funding against its margin and advances the snapshot.
public fun settle_funding(market: &Market, pos: &mut Position) {
    let owed = (market.cumulative_funding - pos.funding_index_at_settle) * pos.size / SCALE;
    pos.margin = if (pos.margin > owed) { pos.margin - owed } else { 0 };
    pos.funding_index_at_settle = market.cumulative_funding;
}

/// PB-1 candidate: `size` is mutated first, so the funding accrued on the OLD size is charged on
/// the NEW size (or, with a prior `decrease`, dodged entirely). Settlement must be the first
/// state-mutating operation.
public fun increase_position(market: &Market, pos: &mut Position, delta: u64) {
    assert!(delta > 0, EZeroAmount);
    pos.size = pos.size + delta;
    settle_funding(market, pos);
}

/// PB-1 candidate: margin is topped up before the pending debt is applied, so the margin check
/// that follows runs against a figure the settlement has not yet reduced.
public fun add_collateral(market: &Market, pos: &mut Position, amount: u64) {
    assert!(amount > 0, EZeroAmount);
    pos.margin = pos.margin + amount;
    settle_funding(market, pos);
}

/// Known-good ordering for contrast: settle first, then mutate and check.
public fun remove_collateral(market: &Market, pos: &mut Position, amount: u64) {
    settle_funding(market, pos);
    assert!(pos.margin >= amount, EInsufficientMargin);
    pos.margin = pos.margin - amount;
}

public fun margin(pos: &Position): u64 {
    pos.margin
}

public fun size(pos: &Position): u64 {
    pos.size
}
