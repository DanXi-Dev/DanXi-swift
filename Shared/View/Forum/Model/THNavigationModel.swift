import SwiftUI

@MainActor
class THNavigationModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var page = THPage.browse
}

enum THPage {
    case browse
    case favorite
    case mypost
    case notifications
    case messages
    case report
}
