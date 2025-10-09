import SwiftUI
import TipKit

@available(iOS 17.0, *)
struct EditFeaturesTip: Tip {
    var title: Text{
        Text("Edit Home Page")
    }
    var message : Text? {
        Text("Choose which features you want to show on the home page.")
    }
}
