import Foundation
import NIOIMAPCore

/// Mutable accumulator for one FETCH line of a CHANGEDSINCE flag fetch.
struct FlagChangeRecord: Sendable {
    var uid: UID?
    var flags: [Flag]?
    var modSequence: UInt64?
}

final class FetchFlagChangesHandler: BaseIMAPCommandHandler<[FlagChangeRecord]>,
    IMAPCommandHandler, @unchecked Sendable {

    private var records: [FlagChangeRecord] = []

    override func handleTaggedOKResponse(_ response: TaggedResponse) {
        super.handleTaggedOKResponse(response)
        succeedWithResult(lock.withLock { self.records })
    }

    override func handleTaggedErrorResponse(_ response: TaggedResponse) {
        failWithError(IMAPError.fetchFailed(String(describing: response.state)))
    }

    override func processResponse(_ response: Response) -> Bool {
        let handled = super.processResponse(response)
        if case .fetch(let fetchResponse) = response {
            switch fetchResponse {
                case .start:
                    lock.withLock { self.records.append(FlagChangeRecord()) }
                case .simpleAttribute(let attribute):
                    lock.withLock {
                        guard let index = self.records.indices.last else { return }
                        switch attribute {
                            case .uid(let uid): self.records[index].uid = UID(nio: uid)
                            case .flags(let flags): self.records[index].flags = flags.map(Flag.init(nio:))
                            case .fetchModificationSequence(let value):
                                self.records[index].modSequence = UInt64(value)
                            default: break
                        }
                    }
                default: break
            }
        }
        return handled
    }
}
