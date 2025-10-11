import SwiftUI
import TipKit

@available(iOS 17.0, *)
struct ChangeVisibilityTip: Tip {
    var title: Text{
        Text("Change Visibility for Folded Content")
    }
    var message : Text? {
        Text("Choose how folded content appear in the list.")
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
struct FavoriteOrSubscribeTip: Tip {
    var title: Text{
        Text("Favorite or Subscribe")
    }
    var message : Text? {
        Text("Add this hole to Favorites or Subscribe to keep track of new updates.")
    }
}
