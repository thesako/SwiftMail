import Foundation

/// Gmail-native attributes for a message, exposed via the `X-GM-EXT-1` IMAP capability.
///
/// Gmail's IMAP extension reports a message ID and thread ID that are stable across
/// mailbox moves (unlike UIDs, which are only stable within a single mailbox), plus the
/// set of Gmail labels applied to the message. See
/// `IMAPServer.fetchGmailAttributes(for:)`.
public struct GmailMessageAttributes: Sendable, Hashable {
    /// Gmail's persistent message ID (`X-GM-MSGID`), stable across mailboxes.
    public let messageID: UInt64

    /// Gmail's persistent thread ID (`X-GM-THRID`), shared by every message in a thread.
    public let threadID: UInt64

    /// The Gmail labels applied to the message (`X-GM-LABELS`), including system labels
    /// such as `\Inbox` and `\Important` alongside user-defined labels.
    public let labels: [String]

    /// Initialize a new set of Gmail message attributes.
    /// - Parameters:
    ///   - messageID: Gmail's persistent message ID.
    ///   - threadID: Gmail's persistent thread ID.
    ///   - labels: The Gmail labels applied to the message.
    public init(messageID: UInt64, threadID: UInt64, labels: [String], flags: [Flag]? = nil) {
        self.messageID = messageID
        self.threadID = threadID
        self.labels = labels
        self.flags = flags
    }

    /// The message's flags, when they were requested (`includeFlags`); nil otherwise.
    public let flags: [Flag]?

    /// Complete records keyed by returned UID; partial ones are dropped.
    static func results(from records: [GmailAttributeRecord]) -> [UID: GmailMessageAttributes] {
        var result: [UID: GmailMessageAttributes] = [:]
        for record in records {
            guard let uid = record.uid, let messageID = record.messageID, let threadID = record.threadID
            else { continue }
            result[uid] = GmailMessageAttributes(messageID: messageID, threadID: threadID,
                                                 labels: record.labels, flags: record.flags)
        }
        return result
    }
}
