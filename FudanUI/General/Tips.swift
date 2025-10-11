import SwiftUI
import TipKit

@available(iOS 17.0, *)
struct EditFeaturesTip: Tip {
    var title: Text{
        Text("Edit Home Page", bundle: .module)
    }
    var message : Text? {
        Text("Choose which features you want to show on the home page.", bundle: .module)
    }
}

@available(iOS 17.0, *)
struct ExportToCalendarTip: Tip {
    var title: Text{
        Text("Export to Calendar", bundle: .module)
    }
    var message : Text? {
        Text("Export class schedule to your device calendar.", bundle: .module)
    }
}
