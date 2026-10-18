import Foundation
import NIO
import NIOEmbedded
@preconcurrency import NIOIMAP
@preconcurrency import NIOIMAPCore
import Testing
@testable import SwiftMail

@Suite(.serialized, .timeLimit(.minutes(1)))
struct SubscribeAndFlagChangesTests {
    @Test
    func serializesSubscribe() async throws {
        let wire = try await Self.wire(SubscribeMailboxCommand(mailboxName: "Folders/Work").toTaggedCommand(tag: "S001"))
        #expect(wire == "S001 SUBSCRIBE \"Folders/Work\"\r\n")
    }

    @Test
    func serializesChangedSinceFlagFetch() async throws {
        let command = FetchFlagChangesCommand(identifierSet: UIDSet(UID(1)...), changedSince: 42)
        let wire = try await Self.wire(command.toTaggedCommand(tag: "F001"))
        #expect(wire == "F001 UID FETCH 1:* (UID FLAGS MODSEQ) (CHANGEDSINCE 42)\r\n")
    }

    @Test
    func rejectsEmptySet() {
        #expect(throws: IMAPError.self) {
            try FetchFlagChangesCommand(identifierSet: UIDSet(), changedSince: 1).validate()
        }
    }

    @Test
    func handlerDecodesUidFlagsAndModSeq() async throws {
        let channel = try await NIOAsyncTestingChannel.withIMAPClientHandler()
        let promise = channel.eventLoop.makePromise(of: [FlagChangeRecord].self)
        try await channel.pipeline.addHandler(FetchFlagChangesHandler(commandTag: "A001", promise: promise))
        try await channel.writeAndFlush(IMAPClientHandler.OutboundIn.part(.tagged(TaggedCommand(tag: "A001", command: .noop))))
        _ = try await channel.readOutbound(as: ByteBuffer.self)
        for line in ["* 3 FETCH (UID 7 FLAGS (\\Seen \\Flagged) MODSEQ (99))\r\n", "A001 OK FETCH completed\r\n"] {
            try await channel.writeInbound(ByteBuffer(string: line))
        }
        let records = try await promise.futureResult.get()
        #expect(records.count == 1)
        #expect(records[0].uid == UID(7))
        #expect(records[0].flags == [.seen, .flagged])
        #expect(records[0].modSequence == 99)
    }

    private static func wire(_ tagged: TaggedCommand) async throws -> String? {
        let channel = try await NIOAsyncTestingChannel.withIMAPClientHandler()
        try await channel.writeAndFlush(IMAPClientHandler.OutboundIn.part(CommandStreamPart.tagged(tagged)))
        guard var buffer = try await channel.readOutbound(as: ByteBuffer.self) else { return nil }
        return buffer.readString(length: buffer.readableBytes)
    }
}
