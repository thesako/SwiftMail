import Foundation
import NIOIMAPCore
import NIO

/** Command to subscribe to a mailbox */
struct SubscribeMailboxCommand: IMAPTaggedCommand {
    typealias ResultType = Void
    typealias HandlerType = SubscribeMailboxHandler

    let mailboxName: String

    func toTaggedCommand(tag: String) -> TaggedCommand {
        TaggedCommand(tag: tag, command: .subscribe(MailboxName(ByteBuffer(string: mailboxName))))
    }
}
