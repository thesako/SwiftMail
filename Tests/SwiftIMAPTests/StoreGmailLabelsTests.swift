import Foundation
import NIO
import NIOEmbedded
@preconcurrency import NIOIMAP
@preconcurrency import NIOIMAPCore
import Testing
@testable import SwiftMail

/// `UID STORE … ±X-GM-LABELS.SILENT (…)`: Gmail's label edit.
struct StoreGmailLabelsTests {
    private func wire(_ command: StoreGmailLabelsCommand) async throws -> String {
        let channel = try await NIOAsyncTestingChannel.withIMAPClientHandler()
        let part = IMAPClientHandler.OutboundIn.part(CommandStreamPart.tagged(command.toTaggedCommand(tag: "A001")))
        try await channel.writeAndFlush(part)
        var outbound = try #require(try await channel.readOutbound(as: ByteBuffer.self))
        return outbound.readString(length: outbound.readableBytes) ?? ""
    }

    @Test
    func testSystemLabelsGoBareUserLabelsQuoted() async throws {
        let command = try StoreGmailLabelsCommand(identifierSet: UIDSet([UID(7), UID(9)]),
                                                  labels: ["\\Inbox", "Work"], operation: .remove)
        #expect(try await wire(command).contains("UID STORE 7,9 -X-GM-LABELS.SILENT (\\Inbox \"Work\")"))
    }

    @Test
    func testNonASCIILabelIsModifiedUTF7() async throws {
        let command = try StoreGmailLabelsCommand(identifierSet: UIDSet([UID(1)]), labels: ["Reçus"], operation: .add)
        #expect(try await wire(command).contains("+X-GM-LABELS.SILENT (\"Re&AOc-us\")"))
    }

    @Test
    func testNestedLabelKeepsItsSlash() async throws {
        let command = try StoreGmailLabelsCommand(identifierSet: UIDSet([UID(1)]), labels: ["Work/2026"], operation: .add)
        #expect(try await wire(command).contains("+X-GM-LABELS.SILENT (\"Work/2026\")"))
    }

    @Test
    func testEmptySetIsRejected() throws {
        let command = try StoreGmailLabelsCommand(identifierSet: UIDSet(), labels: ["Work"], operation: .add)
        #expect(throws: IMAPError.self) { try command.validate() }
    }
}
