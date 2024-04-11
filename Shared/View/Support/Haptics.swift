import UIKit

let notificationHaptic = UINotificationFeedbackGenerator()

/// This prepares the haptic engine, reducing the latency for triggers that may occur shortly after.
/// Though optional, this is highly recommended.
/// Preparing the haptic engine takes time, and triggering haptics immediately after calling prepare does not help at all
/// It is best to call prepare before an async operation and trigger after it completes.
func prepareHaptic() {
    notificationHaptic.prepare()
}

func haptic(_ notificationType: UINotificationFeedbackGenerator.FeedbackType = .success) {
    notificationHaptic.notificationOccurred(notificationType)
}
