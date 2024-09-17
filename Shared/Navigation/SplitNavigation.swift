import SwiftUI
import FudanKit
import FudanUI
import DanXiUI
import ViewUtils

struct SplitNavigation: View {
    @Binding var screen: AppScreen
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    private var isSettings: Bool {
        screen == .settings
    }
    
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
    @ObservedObject private var communityModel = CommunityModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    @ObservedObject private var settings = ForumSettings.shared
    
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
            
            if communityModel.loggedIn {
                if settings.previewFeatureSetting != .focus {
                    AppScreen.forum.label
                        .tag(AppScreen.forum)
                    
                    AppScreen.curriculum.label
                        .tag(AppScreen.curriculum)
                }
                
                if settings.previewFeatureSetting != .hide {
                    AppScreen.innovation.label
                        .tag(AppScreen.innovation)
                }
            }
            
            AppScreen.settings.label
                .tag(AppScreen.settings)
        }
        .navigationTitle("DanXi")
        .navigationBarTitleDisplayMode(.large)
    }
}
