import FilterCore
import IdentityLookup

/// Glue only. Every classification decision lives in `FilterCore`; this file
/// reads config, calls the classifier, maps the verdict, and fails open.
final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context _: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterQueryResponse) -> Void
    ) {
        // Defaults to `.none`: if anything below is skipped, the message is delivered.
        let response = ILMessageFilterQueryResponse()
        AppGroup.recordRun()

        guard let body = queryRequest.messageBody else {
            completion(response)
            return
        }

        let verdict = Classifier.classify(
            sender: queryRequest.sender ?? "",
            body: body,
            config: AppGroup.config()
        )
        response.action = verdict.action.ilAction
        response.subAction = verdict.subAction.ilSubAction
        if verdict.action == .junk {
            AppGroup.recordBlocked()
        }

        completion(response)
    }
}

extension MessageFilterExtension: ILMessageFilterCapabilitiesQueryHandling {
    func handle(
        _: ILMessageFilterCapabilitiesQueryRequest,
        context _: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterCapabilitiesQueryResponse) -> Void
    ) {
        let response = ILMessageFilterCapabilitiesQueryResponse()
        response.transactionalSubActions = [.transactionalFinance, .transactionalOrders, .transactionalReminders]
        response.promotionalSubActions = [.promotionalOffers]
        completion(response)
    }
}
