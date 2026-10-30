// Fixture c12-bridge-single-verifier: a minimal inbound bridge vault whose verifier set may be a
// 1-of-1 configuration, whose replay protection is a bare nonce, and whose refund path pays the
// caller's claimed amount instead of the recorded deposit. Those three omissions are the ONLY
// deviations from the auditor's guidance. Never deploy.
module c12_bridge_single_verifier::bridge;

use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use sui::table::{Self, Table};

const EEmptyVerifierSet: u64 = 0;
const ENotVerifier: u64 = 1;
const ENonceUsed: u64 = 2;
const EAlreadyAttested: u64 = 3;
const ENoDeposit: u64 = 4;
const EInsufficientVault: u64 = 5;

/// Admin capability: only the holder may create a bridge instance.
public struct AdminCap has key, store {
    id: UID,
}

/// CHK-C12-1 candidate struct: `members` may hold a single address and `threshold` may be `1`;
/// `create` accepts that configuration without a minimum-of-two invariant.
public struct VerifierSet has store {
    members: vector<address>,
    threshold: u64,
}

/// Attestations collected so far for one nonce. The payload (`recipient`, `amount`) is NOT part
/// of the replay key — see `attest`.
public struct Pending has store, drop {
    attesters: vector<address>,
    recipient: address,
    amount: u64,
}

public struct Bridge has key {
    id: UID,
    verifiers: VerifierSet,
    /// CHK-C12-2 candidate field: replay protection keyed by `nonce` only.
    used_nonces: Table<u64, bool>,
    pending: Table<u64, Pending>,
    /// Per-depositor recorded deposits, consulted (but not enforced) by `refund`.
    deposits: Table<address, u64>,
    vault: Balance<SUI>,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
}

/// CHK-C12-1 candidate: the only invariant is "non-empty"; `members = [x], threshold = 1` passes.
public fun create(_: &AdminCap, members: vector<address>, threshold: u64, ctx: &mut TxContext) {
    assert!(members.length() > 0 && threshold > 0 && threshold <= members.length(), EEmptyVerifierSet);
    transfer::share_object(Bridge {
        id: object::new(ctx),
        verifiers: VerifierSet { members, threshold },
        used_nonces: table::new(ctx),
        pending: table::new(ctx),
        deposits: table::new(ctx),
        vault: balance::zero(),
    });
}

/// Lock SUI into the vault and record the depositor's total.
public fun deposit(bridge: &mut Bridge, coin: Coin<SUI>, ctx: &TxContext) {
    let sender = ctx.sender();
    let amount = coin.value();
    if (bridge.deposits.contains(sender)) {
        let recorded = bridge.deposits.borrow_mut(sender);
        *recorded = *recorded + amount;
    } else {
        bridge.deposits.add(sender, amount);
    };
    bridge.vault.join(coin.into_balance());
}

/// A verifier attests an inbound message. CHK-C12-2 candidate: uniqueness is `nonce` alone — the
/// payload is overwritten by the latest attester and nothing binds the attestations to a hash of
/// `(nonce, recipient, amount)`; once `threshold` attesters are counted the payout is released.
public fun attest(bridge: &mut Bridge, nonce: u64, recipient: address, amount: u64, ctx: &mut TxContext) {
    let sender = ctx.sender();
    assert!(bridge.verifiers.members.contains(&sender), ENotVerifier);
    assert!(!bridge.used_nonces.contains(nonce), ENonceUsed);
    if (!bridge.pending.contains(nonce)) {
        bridge.pending.add(nonce, Pending { attesters: vector[], recipient, amount });
    };
    let entry = bridge.pending.borrow_mut(nonce);
    assert!(!entry.attesters.contains(&sender), EAlreadyAttested);
    entry.attesters.push_back(sender);
    entry.recipient = recipient;
    entry.amount = amount;
    if (entry.attesters.length() >= bridge.verifiers.threshold) {
        let Pending { attesters: _, recipient, amount } = bridge.pending.remove(nonce);
        bridge.used_nonces.add(nonce, true);
        assert!(bridge.vault.value() >= amount, EInsufficientVault);
        transfer::public_transfer(coin::from_balance(bridge.vault.split(amount), ctx), recipient);
    };
}

/// CHK-C12-3 candidate: the refund pays `claimed_amount`, bounded only by the vault balance; the
/// recorded `deposited` value is removed but never compared against the claim.
public fun refund(bridge: &mut Bridge, claimed_amount: u64, ctx: &mut TxContext): Coin<SUI> {
    let sender = ctx.sender();
    assert!(bridge.deposits.contains(sender), ENoDeposit);
    let _deposited = bridge.deposits.remove(sender);
    assert!(bridge.vault.value() >= claimed_amount, EInsufficientVault);
    coin::from_balance(bridge.vault.split(claimed_amount), ctx)
}

public fun vault_value(bridge: &Bridge): u64 {
    bridge.vault.value()
}
