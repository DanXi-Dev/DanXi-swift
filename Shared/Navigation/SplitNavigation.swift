import SwiftUI
import FudanKit
import FudanUI
import ViewUtils

struct SplitNavigation: View {
    @Binding var screen: AppScreen?
    
    var body: some View {
        NavigationSplitView {
            AppSidebarList(screen: $screen)
        } content: {
            screen?.content
        } detail: {
            screen?.detail
        }
    }
}

struct AppSidebarList: View {
    @Binding var screen: AppScreen?
    @ObservedObject private var communityModel = DXModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    
    var body: some View {
        NavigationStack {
            List(selection: $screen) {
                if campusModel.loggedIn {
                    AppScreen.campus.label
                        .tag(AppScreen.campus)
                }
                
                if communityModel.isLogged {
                    AppScreen.forum.label
                        .tag(AppScreen.forum)
                    
                    AppScreen.curriculum.label
                        .tag(AppScreen.curriculum)
                }
                
                AppScreen.settings.label
                    .tag(AppScreen.settings)
            }
            .navigationTitle("DanXi")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
