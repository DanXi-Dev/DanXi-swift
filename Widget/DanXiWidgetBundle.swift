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
