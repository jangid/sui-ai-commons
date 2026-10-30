// Fixture c11-governance-capture: a deliberately vulnerable treasury-governance module.
// The vulnerable shape (live-balance voting, zero quorum, no execution delay, unrestricted
// payload, no vote-token lock) is the ONLY deviation from the auditor's guidance; everything
// else (named error constants, `&Clock`, shared objects) follows it. Never deploy.
module c11_governance_capture::governance;

use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::{Self, Coin};
use sui::sui::SUI;

/// Governance token marker; `Coin<GOV>` is the voting asset.
public struct GOV has drop {}

/// CHK-C11-2 candidate: quorum floor is an absolute constant of zero, so a single yes vote
/// passes any proposal regardless of total voting supply. No proposer threshold exists either.
const QUORUM: u64 = 0;

const EVotingClosed: u64 = 0;
const EProposalNotPassed: u64 = 1;
const EAlreadyExecuted: u64 = 2;

/// Shared treasury the governance payload drains from.
public struct Treasury has key {
    id: UID,
    funds: Balance<SUI>,
}

/// CHK-C11-4 candidate: the payload is a generic `(target, amount)` transfer rather than an
/// allow-listed, capability-gated action.
public struct Proposal has key {
    id: UID,
    target: address,
    amount: u64,
    yes_votes: u64,
    no_votes: u64,
    voting_ends_ms: u64,
    executed: bool,
}

fun init(ctx: &mut TxContext) {
    transfer::share_object(Treasury { id: object::new(ctx), funds: balance::zero() });
}

/// Anyone may fund the treasury.
public fun deposit(treasury: &mut Treasury, payment: Coin<SUI>) {
    treasury.funds.join(payment.into_balance());
}

/// Anyone may propose a transfer of any amount to any address (no proposer threshold).
public fun propose(
    target: address,
    amount: u64,
    voting_period_ms: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let proposal = Proposal {
        id: object::new(ctx),
        target,
        amount,
        yes_votes: 0,
        no_votes: 0,
        voting_ends_ms: clock.timestamp_ms() + voting_period_ms,
        executed: false,
    };
    transfer::share_object(proposal);
}

/// CHK-C11-1 candidate: voting power is the LIVE balance of the ballot coin at vote time, not a
/// snapshot taken before proposal creation, so flash-loaned `GOV` counts in full.
/// CHK-C11-5 candidate: the ballot is only borrowed; nothing locks it or records that it voted,
/// so the same coins can be transferred to another account and voted again in the same period.
public fun vote(proposal: &mut Proposal, ballot: &Coin<GOV>, support: bool, clock: &Clock) {
    assert!(clock.timestamp_ms() <= proposal.voting_ends_ms, EVotingClosed);
    let weight = ballot.value();
    if (support) {
        proposal.yes_votes = proposal.yes_votes + weight;
    } else {
        proposal.no_votes = proposal.no_votes + weight;
    };
}

/// CHK-C11-3 candidate: executable the moment `yes > no`, with no delay between pass and
/// execution (the voting deadline is not even checked), and no guardian/veto path exists.
/// Propose, vote and execute can therefore all happen inside one PTB.
public fun execute_proposal(proposal: &mut Proposal, treasury: &mut Treasury, ctx: &mut TxContext) {
    assert!(!proposal.executed, EAlreadyExecuted);
    assert!(
        proposal.yes_votes > proposal.no_votes && proposal.yes_votes >= QUORUM,
        EProposalNotPassed,
    );
    proposal.executed = true;
    let payout = coin::take(&mut treasury.funds, proposal.amount, ctx);
    transfer::public_transfer(payout, proposal.target);
}
