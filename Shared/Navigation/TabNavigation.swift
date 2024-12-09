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
    
    @StateObject private var campusTabModel = TabViewModel()
    @StateObject private var forumTabModel = TabViewModel()
    @StateObject private var curriculumTabModel = TabViewModel()
    @StateObject private var calendarTabModel = TabViewModel()
    @StateObject private var communityTabModel = TabViewModel()
    @StateObject private var settingsTabModel = TabViewModel()
    
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
        let screenBinding = Binding<AppScreen> {
            screen
        } set: { newScreen in
            if newScreen == screen {
                switch screen {
                case .campus:
                    campusTabModel.navigationControl.send()
                case .forum:
                    forumTabModel.navigationControl.send()
                case .curriculum:
                    curriculumTabModel.navigationControl.send()
                case .community:
                    communityTabModel.navigationControl.send()
                case .calendar:
                    calendarTabModel.navigationControl.send()
                case .settings:
                    settingsTabModel.navigationControl.send()
                default:
                    break
                }
            } else {
                screen = newScreen
            }
        }
        
        TabView(selection: screenBinding) {
            if campusModel.loggedIn {
                TabViewItem(tag: AppScreen.campus) {
                    AppScreen.campus.content
                } label: {
                    AppScreen.campus.label
                }
                .environmentObject(campusTabModel)
            }
            
            if communityModel.loggedIn {
                if settings.previewFeatureSetting != .focus {
                    TabViewItem(tag: AppScreen.forum) {
                        AppScreen.forum.content
                    } label: {
                        AppScreen.forum.label
                    }
                    .environmentObject(forumTabModel)
                }
                
                switch settings.previewFeatureSetting {
                case .focus:
                    NavigationStack {
                        InnovationHomePage()
                    }
                    .tag(AppScreen.innovation)
                    .tabItem {
                        AppScreen.innovation.label
                    }
                case .hide:
                    TabViewItem(tag: AppScreen.curriculum) {
                        AppScreen.curriculum.content
                    } label: {
                        AppScreen.curriculum.label
                    }
                    .environmentObject(curriculumTabModel)
                case .show:
                    TabViewItem(tag: AppScreen.community) {
                        AppScreen.community.content
                    } label: {
                        AppScreen.community.label
                    }
                    .environmentObject(communityTabModel)
                }
            }
            
            if campusModel.loggedIn {
                TabViewItem(tag: AppScreen.calendar) {
                    AppScreen.calendar.content
                } label: {
                    AppScreen.calendar.label
                }
                .environmentObject(calendarTabModel)
            }
            
            TabViewItem(tag: AppScreen.settings) {
                AppScreen.settings.content
            } label: {
                AppScreen.settings.label
            }
            .environmentObject(settingsTabModel)
        }
        .id(loginStatus) // force the tabview to redraw after tab item changes. This is a workaround for a bug on iOS 17.
    }
}
