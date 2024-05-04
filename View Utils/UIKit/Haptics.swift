import UIKit

@MainActor
/// Perform an asynchronous operation, and provide a haptic feedback.
/// - Parameters:
///   - success: Whether to provide haptics when the operation succeed.
///   - fail: Whether to provide haptics when the operation fails.
///   - action: The asynchronous operation to perform.
public func withHaptics(success: Bool = true, fail: Bool = true, action: () async throws -> Void) async rethrows {
    let notificationHaptic = UINotificationFeedbackGenerator()
    notificationHaptic.prepare()
    do {
        try await action()
        if success {
            notificationHaptic.notificationOccurred(.success)
        }
    } catch {
        if fail {
            notificationHaptic.notificationOccurred(.error)
        }
        throw error
    }
}
