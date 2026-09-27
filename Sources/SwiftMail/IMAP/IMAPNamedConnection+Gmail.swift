import Foundation
import NIOIMAPCore

extension IMAPNamedConnection {
    /// Whether this connection advertised Gmail's `X-GM-EXT-1` capability.
    public var supportsGmailExtensions: Bool {
        capabilities.containsGmailExtensionsCapability
    }

    /// Fetches Gmail-native attributes for the given UIDs on this named connection.
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
