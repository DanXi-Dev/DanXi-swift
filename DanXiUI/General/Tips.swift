import SwiftUI
import TipKit

@available(iOS 17.0, *)
struct ChangeVisibilityTip: Tip {
    var title: Text{
        Text("Change Visibility for Folded Content", bundle: .module)
    }
    var message : Text? {
        Text("Choose how folded content appear in the list.", bundle: .module)
    }
    var image: Image? {
        Image(systemName: "eye")
    }
    var actions: [Action] {
        [
            Action(id: "go-to-settings", title: "Go to settings")
        ]
    }
}

@available(iOS 17.0, *)
public struct FavoriteOrSubscribeTip: Tip {
    public var title: Text{
        Text("Favorite or Subscribe", bundle: .module)
    }
    public var message : Text? {
        Text("Add this hole to Favorites or Subscribe to keep track of new updates.", bundle: .module)
    }
}
