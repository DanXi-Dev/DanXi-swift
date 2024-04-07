import SwiftUI
import FudanKit
import CampusUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model: AppModel
    
    init() {
        let model = AppModel()
        
        if CampusModel.shared.loggedIn {
            model.section = .campus
        } else if DXModel.shared.isLogged {
            model.section = .forum
        } else {
            model.section = .settings
        }
        
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                TabHomePage()
            } else {
                SplitHomePage()
            }
        }
        .environmentObject(model)
        .onOpenURL { url in
            model.openURL(url)
        }
        .onReceive(AppModel.notificationPublisher) { content in
            model.section = .forum
        }
        .onReceive(AppModel.notificationSettingsPublisher) { content in
            model.section = .settings
        }
        .sheet(isPresented: $model.showIntro) {
            IntroSheet()
                .environmentObject(model)
        }
    }
}


struct TabHomePage: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var forumModel = DXModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    
    private var loginStatus: Int {
        let forumStatus = forumModel.isLogged ? 2 : 0
        let campusStatus = campusModel.loggedIn ? 1 : 0
        return forumStatus + campusStatus
    }
    
    var body: some View {
        TabView(selection: $model.section) {
            if campusModel.loggedIn {
                CampusHomePage()
                    .tag(AppSection.campus)
                    .tabItem {
                        Label("Campus.Tab", systemImage: "square.stack")
                    }
            }
            
            if forumModel.isLogged {
                THHomePage()
                    .tag(AppSection.forum)
                    .tabItem {
                        Label("Forum", systemImage: "text.bubble")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
                
                DKHomePage()
                    .tag(AppSection.curriculum)
                    .tabItem {
                        Label("Curriculum", systemImage: "books.vertical")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
            }
            
            if campusModel.loggedIn {
                CoursePage()
                    .tag(AppSection.calendar)
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
            }
            
            SettingsPage()
                .tag(AppSection.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        // this is a workaround for a bug in iOS 17 causing the setting page to blank when logout
        // reset the id will redraw everything
        .id(loginStatus)
    }
}

struct SplitHomePage: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var forumModel = DXModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    
    var body: some View {
        NavigationSplitView {
            let sectionBinding = Binding<AppSection?>(
                get: { model.section },
                set: { if let section = $0 { model.section = section } }
            )
            
            List(selection: sectionBinding) {
                if campusModel.loggedIn {
                    Label("Campus.Tab", systemImage: "square.stack")
                        .tag(AppSection.campus)
                }
                if forumModel.isLogged {
                    Label("Forum", systemImage: "text.bubble")
                        .tag(AppSection.forum)
                    Label("Curriculum", systemImage: "books.vertical")
                        .tag(AppSection.curriculum)
                }
                if campusModel.loggedIn {
                    Label("Calendar", systemImage: "calendar")
                        .tag(AppSection.calendar)
                }
                Label("Settings", systemImage: "gearshape")
                    .tag(AppSection.settings)
            }
            .navigationTitle("DanXi")
        } detail: {
            if #available(iOS 17, *) {
                switch model.section {
                case .campus:
                    CampusHomePage()
                case .forum:
                    THHomePage()
                case .curriculum:
                    DKHomePage()
                case .calendar:
                    CoursePage()
                case .settings:
                    SettingsPage()
                }
            } else {
                // FIXME: This ZStack is a workaround for SwiftUI bug 91311311 on iOS 16
                // > Conditional views in columns of NavigationSplitView fail to update on some state changes.
                // > Workaround: Wrap the contents of the column in a ZStack.
                //
                // Yet it seems this workaround causes issues on Mac Catalyst, so we should apply it only if we must
                ZStack {
                    switch model.section {
                    case .campus:
                        CampusHomePage()
                    case .forum:
                        THHomePage()
                    case .curriculum:
                        DKHomePage()
                    case .calendar:
                        CoursePage()
                    case .settings:
                        SettingsPage()
                    }
                }
            }
        }
    }
}
