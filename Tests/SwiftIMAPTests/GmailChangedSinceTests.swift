import Foundation
import NIO
import NIOEmbedded
@preconcurrency import NIOIMAP
@preconcurrency import NIOIMAPCore
import Testing
@testable import SwiftMail

/// CONDSTORE `CHANGEDSINCE` and FLAGS on the Gmail attribute fetch, for
/// incremental sync: only messages changed since a known MODSEQ, with flags.
extension FetchGmailAttributesTests {
    @Test
    func testChangedSinceAndFlagsAreOnTheWire() async throws {
        let channel = try await NIOAsyncTestingChannel.withIMAPClientHandler()
        let command = FetchGmailAttributesCommand(identifierSet: UIDSet([UID(1)]), changedSince: 42, includeFlags: true)
        let wrapped = IMAPClientHandler.OutboundIn.part(CommandStreamPart.tagged(command.toTaggedCommand(tag: "A001")))
        try await channel.writeAndFlush(wrapped)

        var outbound = try #require(try await channel.readOutbound(as: ByteBuffer.self))
        let wire = outbound.readString(length: outbound.readableBytes) ?? ""

        #expect(wire.contains("(UID FLAGS X-GM-MSGID X-GM-THRID X-GM-LABELS) (CHANGEDSINCE 42)"))
    }

    /// Incremental sync asks once over the whole mailbox: `1:*`, not UID windows.
    @Test
    func testOpenEndedRangeIsOneStarRange() async throws {
        let channel = try await NIOAsyncTestingChannel.withIMAPClientHandler()
        let command = FetchGmailAttributesCommand(identifierSet: UIDSet(UID(1)...), changedSince: 42, includeFlags: true)
        let wrapped = IMAPClientHandler.OutboundIn.part(CommandStreamPart.tagged(command.toTaggedCommand(tag: "A001")))
        try await channel.writeAndFlush(wrapped)

        var outbound = try #require(try await channel.readOutbound(as: ByteBuffer.self))
        let wire = outbound.readString(length: outbound.readableBytes) ?? ""

        #expect(wire.contains("UID FETCH 1:* (UID FLAGS X-GM-MSGID X-GM-THRID X-GM-LABELS) (CHANGEDSINCE 42)"))
    }

    @Test
    func testWithoutOptionsTheCommandIsUnchanged() {
        let command = FetchGmailAttributesCommand(identifierSet: UIDSet([UID(1)]))
        #expect(command.changedSince == nil && command.includeFlags == false)
    }

    @Test
    func testHandlerDecodesFlags() async throws {
        let records = try await executeFetch([
            "* 1 FETCH (UID 7 FLAGS (\\Seen \\Flagged) MODSEQ (99) X-GM-MSGID 11 X-GM-THRID 12 "
                + "X-GM-LABELS (\"Work\"))\r\n",
            "A001 OK FETCH completed\r\n"
        ])

        #expect(records.count == 1)
        #expect(records[0].flags == [.seen, .flagged])
        #expect(records[0].labels == ["Work"])
    }
}

@Test
func testFlagHashMatchesCaseInsensitiveEquality() {
    #expect(Set<SwiftMail.Flag>([.custom("$Label1"), .custom("$label1"), .seen]).count == 2)
}
