import SwiftUI

struct AppView: View {
    @StateObject var appModel = AppModel()
    
    var body: some View {
        NavigationView{
            TabView {
                /*DashboardPage()
                    .tabItem {
                        Image(systemName: "doc.text.image")
                        Text("dashboard")
                    }*/
                
                TreeHolePage()
                    .tabItem {
                        Image(systemName: "text.bubble")
                        Text("treehole")
                    }
                
                /*CalendarPage()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("agenda")
                    }*/
                
                SettingsPage()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("settings")
                    }
            }
            .navigationTitle("danxi")
        }
        .environmentObject(appModel)
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AppView()
            
            AppView()
                .preferredColorScheme(.dark)
        }
    }
}
