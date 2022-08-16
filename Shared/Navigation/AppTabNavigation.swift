import SwiftUI

struct AppTabNavigation: View {
    @ObservedObject var model = TreeholeDataModel.shared
    
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
                Text("Tree Hole")
            }
            .tag(Tab.treehole)
            
            NavigationView {
                CourseMainPage()
            }
            .tabItem {
                Image(systemName: "books.vertical.fill")
                Text("Curriculum")
            }
            
            NavigationView {
                SettingsPage()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
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
