import FudanUI
import SwiftUI
import WidgetKit

@main
struct DanXiWidgetBundle: WidgetBundle {
    var body: some Widget {
        WalletWidget()
        if #available(iOS 17.0, *) {
            BusWidget()
            ElectricityWidget()
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

@available(iOS 17, *)
#Preview("Electricity level 0-1-2", as: .systemSmall) {
    ElectricityWidget()
} timeline: {
    ElectricityEntity(0)
    ElectricityEntity(1)
    ElectricityEntity(2)
}
