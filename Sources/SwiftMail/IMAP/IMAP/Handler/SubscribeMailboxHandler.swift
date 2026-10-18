import Foundation
import NIOIMAPCore
import NIO
import Logging

/** Handler for the SUBSCRIBE command */
final class SubscribeMailboxHandler: BaseIMAPCommandHandler<Void>, IMAPCommandHandler, @unchecked Sendable {
    typealias ResultType = Void
    typealias InboundIn = Response
    typealias InboundOut = Never

    override func handleTaggedErrorResponse(_ response: TaggedResponse) {
        failWithError(IMAPError.subscribeFailed(String(describing: response.state)))
    }
}
