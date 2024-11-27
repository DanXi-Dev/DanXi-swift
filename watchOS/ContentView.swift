import SwiftUI
import FudanUI
import ViewUtils
import Utils

struct ContentView: View {
    @StateObject private var navigator = AppNavigator()
    
    var body: some View {
        NavigationStack {
            CampusContent()
        }
        .environmentObject(navigator)
    }
}
