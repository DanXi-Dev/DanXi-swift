import SwiftUI
import FudanUI
import FudanKit
import ViewUtils
import Utils

struct ContentView: View {
    @StateObject private var navigator = AppNavigator()
    @ObservedObject private var campusModel = CampusModel.shared
    
    @State private var showLoginSheet = false
    
    var body: some View {
        NavigationStack {
            if campusModel.loggedIn {
                CampusContent()
            } else {
                WatchWelcomePage(showLoginSheet: $showLoginSheet)
            }
        }
        .environmentObject(navigator)
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet()
        }
    }
}
