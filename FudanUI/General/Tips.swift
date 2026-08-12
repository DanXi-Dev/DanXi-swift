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

@available(iOS 17.0, *)
struct PinBookTip: Tip {
    var title: Text {
        Text("Pin Book", bundle: .module)
    }

    var message: Text? {
        Text("Pin this book for quick access from the library search page.", bundle: .module)
    }
}

@available(iOS 17.0, *)
struct PinnedBooksTip: Tip {
    var title: Text {
        Text("Pinned Books", bundle: .module)
    }

    var message: Text? {
        Text("Open pinned books without searching. Swipe right to remove one.", bundle: .module)
    }
}
