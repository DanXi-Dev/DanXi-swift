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

@available(iOS 17.0, *)
struct ExportToCalendarTip: Tip {
    var title: Text{
        Text("Export to Calendar")
    }
    var message : Text? {
        Text("Export class schedule to your device calendar.")
    }
}
