import SwiftUI
import FudanKit
import FudanUI
import ViewUtils

struct SplitNavigation: View {
    @Binding var screen: AppScreen
    @State private var columnVisibility =
    NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            AppSidebarList(screen: $screen)
        } content: {
            screen.content
        } detail: {
            screen.detail
        }
    }
}

struct AppSidebarList: View {
    @Binding var screen: AppScreen
    @ObservedObject private var communityModel = DXModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    
    var body: some View {
        let screenBinding = Binding<AppScreen?>(
            get: { screen },
            set: {
                if let newScreen = $0 {
                    screen = newScreen
                }
            })
        
        List(selection: screenBinding) {
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
