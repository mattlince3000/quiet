import FilterCore
import IdentityLookup

/// The boundary between `FilterCore`'s platform-agnostic verdict and Apple's
/// enums. A mechanical table: no decisions are made here.
extension Verdict.Action {
    var ilAction: ILMessageFilterAction {
        switch self {
        case .none: .none
        case .allow: .allow
        case .junk: .junk
        case .promotion: .promotion
        case .transaction: .transaction
        }
    }
}

extension Verdict.SubAction {
    var ilSubAction: ILMessageFilterSubAction {
        switch self {
        case .none: .none
        case .promotionalOffers: .promotionalOffers
        case .transactionalFinance: .transactionalFinance
        case .transactionalOrders: .transactionalOrders
        case .transactionalReminders: .transactionalReminders
        }
    }
}
