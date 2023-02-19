import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var section: AppSection? = AppSection.campus
    
    var body: some View {
        if horizontalSizeClass == .compact {
            TabHomePage(section: $section)
        } else {
            SplitHomePage(section: $section)
        }
    }
}

enum AppSection {
    case campus, forum, curriculum, settings
}

struct TabHomePage: View {
    @Binding var section: AppSection?
    
    var body: some View {
        // SwiftUI bug: using `Tabview(selection: $section)` will cause selection to change when sheet pops up
        TabView {
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
            
            DKHomePage()
                .tag(AppSection.curriculum)
                .tabItem {
                    Label("Curriculum", systemImage: "books.vertical")
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
    @Binding var section: AppSection?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $section) {
                Label("Campus Services", systemImage: "square.stack")
                    .tag(AppSection.campus)
                Label("Tree Hole", systemImage: "text.bubble")
                    .tag(AppSection.forum)
                Label("Curriculum", systemImage: "books.vertical")
                    .tag(AppSection.curriculum)
                Label("Settings", systemImage: "gearshape")
                    .tag(AppSection.settings)
            }
            .navigationTitle("DanXi")
        } detail: {
            if let section = section {
                switch section {
                case .campus:
                    FDHomePage()
                case .forum:
                    THHomePage()
                case .curriculum:
                    DKHomePage()
                case .settings:
                    SettingsPage()
                }
            }
        }

    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
