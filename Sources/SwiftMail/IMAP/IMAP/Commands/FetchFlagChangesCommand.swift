import Foundation
import NIOIMAPCore

/// `UID FETCH <set> (UID FLAGS MODSEQ) (CHANGEDSINCE <modseq>)` (RFC 7162).
/// The CHANGEDSINCE modifier enables CONDSTORE for the session (§3.1), so no ENABLE is sent.
struct FetchFlagChangesCommand: IMAPTaggedCommand {
    typealias ResultType = [FlagChangeRecord]
    typealias HandlerType = FetchFlagChangesHandler

    let identifierSet: UIDSet
    let changedSince: UInt64
    let timeoutSeconds = 10

    func validate() throws {
        guard !identifierSet.isEmpty else { throw IMAPError.emptyIdentifierSet }
    }

    func toTaggedCommand(tag: String) -> TaggedCommand {
        TaggedCommand(tag: tag, command: .uidFetch(
            .set(identifierSet.toNIOSet()),
            [.uid, .flags, .modificationSequence],
            [.changedSince(ChangedSinceModifier(modificationSequence: ModificationSequenceValue(changedSince)))]
        ))
    }
}
