import Foundation

// MARK: - Equatable Implementation
extension Flag: Equatable {
    public static func == (lhs: Flag, rhs: Flag) -> Bool {
        switch (lhs, rhs) {
            case (.seen, .seen),
                 (.answered, .answered),
                 (.flagged, .flagged),
                 (.deleted, .deleted),
                 (.draft, .draft):
                return true
            case (.custom(let lhsValue), .custom(let rhsValue)):
                return lhsValue.caseInsensitiveCompare(rhsValue) == .orderedSame
            default:
                return false
        }
    }
}

// MARK: - Hashable Implementation
extension Flag: Hashable {
    /// Consistent with `==`: custom flags compare case-insensitively, so they
    /// hash lowercased.
    public func hash(into hasher: inout Hasher) {
        switch self {
            case .seen: hasher.combine(0)
            case .answered: hasher.combine(1)
            case .flagged: hasher.combine(2)
            case .deleted: hasher.combine(3)
            case .draft: hasher.combine(4)
            case .custom(let value): hasher.combine(5); hasher.combine(value.lowercased())
        }
    }
}
