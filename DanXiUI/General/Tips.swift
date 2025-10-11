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
    var actions: [Action] {
        [
            Action(id: "go-to-settings", title: "Go to settings")
        ]
    }
}
