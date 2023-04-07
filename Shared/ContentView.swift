import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject var model = AppModel()
    
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
    }
}


struct TabHomePage: View {
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        TabView(selection: $model.section) {
            FDHomePage()
                .tag(AppSection.campus)
                .tabItem {
                    Label("Campus Services", systemImage: "square.stack")
                }
            
            THHomePage()
                .tag(AppSection.forum)
                .tabItem {
                    Label("Tree Hole", systemImage: "text.bubble")
                }
                .toolbarBackground(.visible, for: .tabBar)
            
            DKHomePage()
                .tag(AppSection.curriculum)
                .tabItem {
                    Label("Curriculum", systemImage: "books.vertical")
                }
                .toolbarBackground(.visible, for: .tabBar)
            
            FDCalendarPageLoader()
                .tag(AppSection.calendar)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
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
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        NavigationSplitView {
            let sectionBinding = Binding<AppSection?>(
                get: { model.section },
                set: { if let section = $0 { model.section = section } }
            )
            
            List(selection: sectionBinding) {
                Label("Campus Services", systemImage: "square.stack")
                    .tag(AppSection.campus)
                Label("Tree Hole", systemImage: "text.bubble")
                    .tag(AppSection.forum)
                Label("Curriculum", systemImage: "books.vertical")
                    .tag(AppSection.curriculum)
                Label("Calendar", systemImage: "calendar")
                    .tag(AppSection.calendar)
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
