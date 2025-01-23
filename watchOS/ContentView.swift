import SwiftUI
import FudanUI
import FudanKit
import ViewUtils
import Utils

struct ContentView: View {
    @StateObject private var navigator = AppNavigator()
    @StateObject private var campusNavigator = CampusNavigator()
    @ObservedObject private var campusModel = CampusModel.shared
    
    @State private var showLoginSheet = false
    
    private func syncCredentials() async throws {
        let state = try await requestCredentialTransfer()
        switch state {
        case .isLogged(let username, let password, let studentType):
            campusModel.forceLogin(username: username, password: password)
            campusModel.studentType = studentType
        case .notLogged:
            campusModel.logout()
        }
    }
    
    var body: some View {
        NavigationStack {
            if campusModel.loggedIn {
                CampusContent()
            } else {
                WatchWelcomePage(showLoginSheet: $showLoginSheet, syncOperation: syncCredentials)
            }
        }
        .environmentObject(navigator)
        .environmentObject(campusNavigator)
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet()
        }
    }
}
