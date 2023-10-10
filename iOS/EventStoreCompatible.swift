import EventKit

extension EKEventStore {
    func requestAccess(handler: @escaping EKEventStoreRequestAccessCompletionHandler) {
        if #available(iOS 17.0, *) {
            requestWriteOnlyAccessToEvents(completion: handler)
        } else {
            requestAccess(to: .event, completion: handler)
        }
    }
}
