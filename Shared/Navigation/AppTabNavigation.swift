import SwiftUI

struct AppTabNavigation: View {
    @ObservedObject var model = treeholeDataModel
    
    enum Tab {
        case treehole
        case settings
    }
    
    @State private var selection: Tab = .treehole
    
    var body: some View {
        TabView(selection: $selection) {
            Group {
                if model.loggedIn {
                    NavigationView {
                        TreeholePage()
                    }
                } else {
                    WelcomePage()
                }
            }
            .tabItem {
                Image(systemName: "text.bubble")
                Text("treehole")
            }
            .tag(Tab.treehole)
            
            NavigationView {
                SettingsPage()
            }
            .navigationViewStyle(.stack)
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
        Group {
            AppTabNavigation()
            AppTabNavigation()
                .preferredColorScheme(.dark)
        }
    }
    
}
