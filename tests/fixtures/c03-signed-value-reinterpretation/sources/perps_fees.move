// Fixture c03-signed-value-reinterpretation: a perps-shaped fee module where an integrator fee
// is stored as raw `u256` bits with no range check and later reinterpreted as a signed
// fixed-point value on the path into a collateral delta. The domain mismatch is the ONLY
// deviation from the auditor's guidance. Never deploy.
module c03_signed_value_reinterpretation::perps_fees;

/// Fixed-point scale: 1.0 == 10^18.
const ONE: u256 = 1_000_000_000_000_000_000;
/// Highest bit of a `u256`; set means "negative" in the two's-complement `IFixed` encoding.
const SIGN_BIT: u256 = 1 << 255;
/// Cap on a single fill's fee, expressed in the UNSIGNED domain (0.1 collateral units).
const MAX_FEE_PER_FILL: u256 = 100_000_000_000_000_000;

const EFeeAboveCap: u64 = 0;
const EInsufficientCollateral: u64 = 1;

/// Local stand-in for a signed fixed-point type (two's complement over `u256`).
public struct IFixed has copy, drop, store {
    bits: u256,
}

/// Per-integrator fee configuration. CHK-C3-1 candidate field: `taker_fee_raw` is written as
/// an unsigned integer and read back as signed `IFixed` by `taker_fee_signed`.
public struct IntegratorInfo has key, store {
    id: UID,
    taker_fee_raw: u256,
}

/// A trader's position; `collateral` is the value sink (PB-5).
public struct Position has key {
    id: UID,
    collateral: u256,
}

/// CHK-C3-2 candidate: stores whatever bits the caller supplies. No `fee <= MAX`, no
/// `!is_negative` check, so `2^256 - 10^23` (reads as -100,000.0) is accepted.
public fun create_integrator_info(fee: u256, ctx: &mut TxContext): IntegratorInfo {
    IntegratorInfo { id: object::new(ctx), taker_fee_raw: fee }
}

public fun open_position(collateral: u256, ctx: &mut TxContext): Position {
    Position { id: object::new(ctx), collateral }
}

/// Reinterprets the raw unsigned bits as a signed fixed-point number (no validation).
fun taker_fee_signed(info: &IntegratorInfo): IFixed {
    IFixed { bits: info.taker_fee_raw }
}

fun is_negative(x: &IFixed): bool {
    x.bits & SIGN_BIT != 0
}

/// Two's-complement magnitude of a negative `IFixed`.
fun negative_magnitude(x: &IFixed): u256 {
    (std::u256::max_value!() - x.bits) + 1
}

/// Signed-fixed-point times an unsigned notional, keeping the sign.
fun mul_notional(rate: &IFixed, notional: u256): IFixed {
    if (is_negative(rate)) {
        let magnitude = negative_magnitude(rate) * notional / ONE;
        IFixed { bits: (std::u256::max_value!() - magnitude) + 1 }
    } else {
        IFixed { bits: rate.bits * notional / ONE }
    }
}

/// Fee path into the collateral sink. CHK-C3-3 candidate: the cap is compared in the unsigned
/// domain (`fee.bits <= MAX_FEE_PER_FILL`) and only guards the branch where the signed read is
/// non-negative; a sign-bit-set fee skips the cap and is credited to the trader as a rebate.
public fun process_fill(pos: &mut Position, info: &IntegratorInfo, notional: u256) {
    let fee = mul_notional(&taker_fee_signed(info), notional);
    if (is_negative(&fee)) {
        // Negative fee read as a rebate: collateral grows by the magnitude, uncapped.
        pos.collateral = pos.collateral + negative_magnitude(&fee);
    } else {
        assert!(fee.bits <= MAX_FEE_PER_FILL, EFeeAboveCap);
        assert!(pos.collateral >= fee.bits, EInsufficientCollateral);
        pos.collateral = pos.collateral - fee.bits;
    };
}

public fun collateral(pos: &Position): u256 {
    pos.collateral
}
