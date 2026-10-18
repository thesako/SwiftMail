import Foundation

/// A message's flags and modification sequence, from a CONDSTORE `CHANGEDSINCE` fetch.
public struct MessageFlagChange: Sendable, Hashable {
    public let uid: UID
    public let flags: [Flag]
    /// The message's `MODSEQ`.
    public let modSequence: UInt64

    public init(uid: UID, flags: [Flag], modSequence: UInt64) {
        self.uid = uid
        self.flags = flags
        self.modSequence = modSequence
    }
}
