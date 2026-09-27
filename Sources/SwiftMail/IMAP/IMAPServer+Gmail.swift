import Foundation
import NIOIMAPCore

extension IMAPServer {
    /// Whether the primary connection advertised Gmail's `X-GM-EXT-1` capability.
    public var supportsGmailExtensions: Bool {
        capabilities.containsGmailExtensionsCapability
    }

    /// Fetches Gmail-native attributes for the given UIDs — optionally with FLAGS,
    /// and only for messages changed since a MODSEQ (CONDSTORE `CHANGEDSINCE`,
    /// which also enables CONDSTORE for the session, RFC 7162 §3.1).
    ///
    /// Requires the `X-GM-EXT-1` capability; other IMAP servers answer with a
    /// tagged BAD. Gate calls on `supportsGmailExtensions`.
    public func fetchGmailAttributes(
        for identifierSet: UIDSet,
        changedSince: UInt64? = nil,
        includeFlags: Bool = false
    ) async throws -> [UID: GmailMessageAttributes] {
        let command = FetchGmailAttributesCommand(
            identifierSet: identifierSet, changedSince: changedSince, includeFlags: includeFlags)
        return GmailMessageAttributes.results(from: try await executeCommand(command))
    }
}
