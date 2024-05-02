import FudanUI
import SwiftUI
import WidgetKit

@main
struct DanXiWigdetBundle: WidgetBundle {
    var body: some Widget {
//        WalletWidget()
        if #available(iOS 17.0, *) {
            BusWidget()
        }
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
