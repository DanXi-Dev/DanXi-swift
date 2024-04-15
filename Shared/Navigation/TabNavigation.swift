import SwiftUI
import FudanKit
import FudanUI
import ViewUtils

struct TabNavigation: View {
    @ObservedObject private var communityModel = DXModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    @Binding var screen: AppScreen?
    
    var body: some View {
        TabView(selection: $screen) {
            if campusModel.loggedIn {
                AppScreen.campus.content
                    .tag(AppScreen.campus)
                    .tabItem {
                        AppScreen.campus.label
                    }
            }
            
            if communityModel.isLogged {
                AppScreen.forum.content
                    .tag(AppScreen.forum)
                    .tabItem {
                        AppScreen.forum.label
                    }
                
                AppScreen.curriculum.content
                    .tag(AppScreen.curriculum)
                    .tabItem {
                        AppScreen.curriculum.label
                    }
            }
            
            if campusModel.loggedIn {
                AppScreen.calendar.content
                    .tag(AppScreen.calendar)
                    .tabItem {
                        AppScreen.calendar.label
                    }
            }
            
            AppScreen.settings.content
                .tag(AppScreen.settings)
                .tabItem {
                    AppScreen.settings.label
                }
        }
    }
}
