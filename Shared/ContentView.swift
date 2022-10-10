import SwiftUI

struct ContentView: View {
    @ObservedObject var model = TreeholeDataModel.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var showSettingPage = false
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    if model.loggedIn {
                        TreeholePage()
                    } else {
                        TreeholeWelcomePage()
                    }
                } label: {
                    Label("Tree Hole", systemImage: "text.bubble")
                }
                
                NavigationLink {
                    if model.loggedIn {
                        CourseMainPage()
                    } else {
                        CourseWelcomePage()
                    }
                } label: {
                    Label("Curriculum", systemImage: "books.vertical")
                }
            }
            .navigationTitle("DanXi")
            .toolbar {
                Button {
                    showSettingPage = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            .sheet(isPresented: $showSettingPage) {
                NavigationView { SettingsPage() }
            }
        }
    }
    
    @ViewBuilder
    private var autoAppNavigation: some View {
        if horizontalSizeClass == .compact {
            AppTabNavigation()
        } else {
            AppSidebarNavigation()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
