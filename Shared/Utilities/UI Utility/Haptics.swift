import UIKit

func haptic() {
    #if os(iOS)
    let impactMed = UIImpactFeedbackGenerator(style: .heavy)
    impactMed.impactOccurred()
    #endif
}
