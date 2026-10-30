// Chunk 0 spike S-2 stub: a minimal non-empty module so the package builds.
// Replaced in Chunk 6 by the real C11 governance-capture fixture.
module c11_governance_capture::governance;

/// Placeholder proposal record; the Chunk 6 fixture fills in the real fields.
public struct Proposal has key, store {
    id: UID,
}
