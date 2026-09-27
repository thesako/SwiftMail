import Foundation
import NIOIMAPCore

struct FetchGmailAttributesCommand: IMAPTaggedCommand {
    typealias ResultType = [GmailAttributeRecord]
    typealias HandlerType = FetchGmailAttributesHandler

    let identifierSet: UIDSet
    /// CONDSTORE (RFC 7162): only messages whose MODSEQ exceeds this value.
    var changedSince: UInt64?
    /// Also fetch FLAGS, for incremental sync.
    var includeFlags = false
    let timeoutSeconds = 10

    init(identifierSet: UIDSet, changedSince: UInt64? = nil, includeFlags: Bool = false) {
        self.identifierSet = identifierSet
        self.changedSince = changedSince
        self.includeFlags = includeFlags
    }

    func validate() throws {
        guard !identifierSet.isEmpty else { throw IMAPError.emptyIdentifierSet }
    }

    func toTaggedCommand(tag: String) -> TaggedCommand {
        // UID is requested explicitly: Gmail need not return messages in the
        // requested order, so responses are keyed by returned UID, not position.
        let attributes: [FetchAttribute] = [.uid] + (includeFlags ? [.flags] : [])
            + [.gmailMessageID, .gmailThreadID, .gmailLabels]
        let modifiers: [FetchModifier] = changedSince.map {
            [.changedSince(ChangedSinceModifier(modificationSequence: ModificationSequenceValue($0)))]
        } ?? []
        return TaggedCommand(tag: tag, command: .uidFetch(
            .set(identifierSet.toNIOSet()), attributes, modifiers
        ))
    }
}
