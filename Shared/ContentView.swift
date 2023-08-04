import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model: AppModel
    
    init() {
        let model = AppModel()
        
        if FDModel.shared.isLogged {
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
        .task {
            await DXModel.shared.loadExtra()
        }
    }
}


struct TabHomePage: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var forumModel = DXModel.shared
    @ObservedObject private var campusModel = FDModel.shared
    
    var body: some View {
        TabView(selection: $model.section) {
            if campusModel.isLogged {
                FDHomePage()
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
            
            if campusModel.isLogged {
                FDCalendarPageLoader()
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
    }
}

struct SplitHomePage: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var forumModel = DXModel.shared
    @ObservedObject private var campusModel = FDModel.shared
    
    var body: some View {
        NavigationSplitView {
            let sectionBinding = Binding<AppSection?>(
                get: { model.section },
                set: { if let section = $0 { model.section = section } }
            )
            
            List(selection: sectionBinding) {
                if campusModel.isLogged {
                    Label("Campus.Tab", systemImage: "square.stack")
                        .tag(AppSection.campus)
                }
                if forumModel.isLogged {
                    Label("Forum", systemImage: "text.bubble")
                        .tag(AppSection.forum)
                    Label("Curriculum", systemImage: "books.vertical")
                        .tag(AppSection.curriculum)
                }
                if campusModel.isLogged {
                    Label("Calendar", systemImage: "calendar")
                        .tag(AppSection.calendar)
                }
                Label("Settings", systemImage: "gearshape")
                    .tag(AppSection.settings)
            }
            .navigationTitle("DanXi")
        } detail: {
                switch model.section {
                case .campus:
                    FDHomePage()
                case .forum:
                    THHomePage()
                case .curriculum:
                    DKHomePage()
                case .calendar:
                    FDCalendarPageLoader()
                case .settings:
                    SettingsPage()
                }
            }
    }
}
