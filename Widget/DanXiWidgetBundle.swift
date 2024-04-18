import WidgetKit
import SwiftUI
import FudanUI

@main
struct DanXiWigdetBundle: WidgetBundle {
    var body: some Widget {
        WalletWidget()
        BusWidget()
    }
}

@available(iOS 17, *)
#Preview("Wallet", as: .systemSmall) {
   WalletWidget()
} timeline: {
   WalletEntry()
}

@available(iOS 17, *)
#Preview("Bus", as: .systemSmall) {
   BusWidget()
} timeline: {
   BusEntry()
}
