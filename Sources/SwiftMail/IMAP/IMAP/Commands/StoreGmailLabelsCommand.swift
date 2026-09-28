import Foundation
import NIO
import NIOIMAPCore

/// `UID STORE … ±X-GM-LABELS.SILENT (…)`: Gmail's label edit (X-GM-EXT-1).
///
/// System labels (`\Inbox`, `\Trash`) go on the wire bare; other labels as IMAP
/// strings in modified UTF-7, the encoding Gmail uses for label names.
struct StoreGmailLabelsCommand: IMAPTaggedCommand {
    typealias ResultType = Void
    typealias HandlerType = StoreHandler

    let identifierSet: UIDSet
    let labels: [GmailLabel]
    let operation: StoreData.StoreType

    init(identifierSet: UIDSet, labels: [String], operation: StoreData.StoreType) throws {
        self.identifierSet = identifierSet
        self.operation = operation
        self.labels = try labels.map { name in
            name.hasPrefix("\\")
                ? GmailLabel(ByteBuffer(string: name))
                // No path separator: a nested label ("Work/2026") is one name.
                : GmailLabel(mailboxName: try MailboxPath.makeRootMailbox(displayName: name).name)
        }
    }

    func validate() throws {
        guard !identifierSet.isEmpty else { throw IMAPError.emptyIdentifierSet }
    }

    func toTaggedCommand(tag: String) -> TaggedCommand {
        let store: StoreGmailLabels
        switch operation {
            case .add: store = .add(silent: true, gmailLabels: labels)
            case .remove: store = .remove(silent: true, gmailLabels: labels)
            case .replace: store = .replace(silent: true, gmailLabels: labels)
        }
        return TaggedCommand(tag: tag, command: .uidStore(.set(identifierSet.toNIOSet()), [], .gmailLabels(store)))
    }
}
