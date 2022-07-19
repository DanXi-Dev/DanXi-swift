import SwiftUI

struct AppView: View {
    @StateObject var appModel = AppModel()
    
    var body: some View {
        TabView {
            DashboardPage()
                .tabItem {
                    Image(systemName: "doc.text.image")
                    Text("首页")
                }
            
            TreeHolePage()
                .tabItem {
                    Image(systemName: "text.bubble")
                    Text("树洞")
                }
            
            CalendarPage()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日程")
                }
            
            SettingsPage()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
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
