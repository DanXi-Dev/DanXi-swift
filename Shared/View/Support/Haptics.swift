import UIKit

func haptic(_ notificationType: UINotificationFeedbackGenerator.FeedbackType = .success) {
    let notificationHaptic = UINotificationFeedbackGenerator()
    notificationHaptic.prepare()
    notificationHaptic.notificationOccurred(notificationType)
}
