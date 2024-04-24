import UIKit

@MainActor
/// Perform an asynchronous operation, and provide a haptic feedback.
/// - Parameters:
///   - success: Whether to provide haptics when the operation succeed.
///   - error: Whether to provide haptics when the operation fails.
///   - action: The asynchronous operation to perform.
/// - Throws: The original error thrown by the operation.
public func withHaptics(success: Bool = true, error: Bool = true, action: () async throws -> Void) async throws {
    let notificationHaptic = UINotificationFeedbackGenerator()
    notificationHaptic.prepare()
    do {
        try await action()
        notificationHaptic.notificationOccurred(.success)
    } catch {
        notificationHaptic.notificationOccurred(.error)
        throw error
    }
}
