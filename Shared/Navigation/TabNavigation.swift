import SwiftUI
import FudanKit
import FudanUI
import ViewUtils
import DanXiUI

struct TabNavigation: View {
    @ObservedObject private var communityModel = CommunityModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    @ObservedObject private var settings = ForumSettings.shared
    @Binding var screen: AppScreen
    
    @StateObject private var campusNavigator = AppNavigator()
    @StateObject private var forumNavigator = AppNavigator()
    @StateObject private var curriculumNavigator = AppNavigator()
    @StateObject private var communityNavigator = AppNavigator()
    
    private enum LoginStatus: Identifiable {
        case none
        case campus
        case community
        case both
        
        var id: LoginStatus { self }
    }
    
    private var loginStatus: LoginStatus {
        if campusModel.loggedIn && communityModel.loggedIn {
            return .both
        } else if campusModel.loggedIn {
            return .campus
        } else if communityModel.loggedIn {
            return .community
        } else {
            return .none
        }
    }
    
    var body: some View {
        TabView(selection: $screen) {
            if campusModel.loggedIn {
                AppScreen.campus.content
                    .environmentObject(campusNavigator)
                    .tag(AppScreen.campus)
                    .tabItem {
                        AppScreen.campus.label
                    }
            }
            
            if communityModel.loggedIn {
                if settings.previewFeatureSetting != .focus {
                    AppScreen.forum.content
                        .environmentObject(forumNavigator)
                        .tag(AppScreen.forum)
                        .tabItem {
                            AppScreen.forum.label
                        }
                }
                
                switch settings.previewFeatureSetting {
                case .focus:
                    InnovationHomePage()
                        .tag(AppScreen.innovation)
                        .tabItem {
                            AppScreen.innovation.label
                        }
                case .hide:
                    AppScreen.curriculum.content
                        .environmentObject(curriculumNavigator)
                        .tag(AppScreen.curriculum)
                        .tabItem {
                            AppScreen.curriculum.label
                        }
                case .show:
                    AppScreen.community.content
                        .environmentObject(communityNavigator)
                        .tag(AppScreen.community)
                        .tabItem {
                            AppScreen.community.label
                        }
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
        .id(loginStatus) // force the tabview to redraw after tab item changes. This is a workaround for a bug on iOS 17.
    }
}
