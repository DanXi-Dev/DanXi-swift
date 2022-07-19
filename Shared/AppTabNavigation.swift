import SwiftUI

struct AppTabNavigation: View {

    enum Tab {
        case treehole
        case settings
    }

    @State private var selection: Tab = .treehole

    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                TreeHolePage()
            }
            .tabItem {
                Image(systemName: "text.bubble")
                Text("treehole")
            }
            .tag(Tab.treehole)
            
            NavigationView {
                SettingsPage()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("settings")
            }
            .tag(Tab.settings)
        }
    }
}

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppTabNavigation()
    }
}
