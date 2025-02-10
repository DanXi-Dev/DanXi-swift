import SwiftUI
import WidgetKit

@main
struct DanXiWidgetBundle: WidgetBundle {
    var body: some Widget {
        WalletWidget()
        if #available(iOS 16.1, *) {
            ElectricityWidget()
        }
        if #available(iOS 17.0, *) {
            BusWidget()
        }
    }
}
