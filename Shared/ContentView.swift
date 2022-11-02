import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var showSettingPage = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                contentList
            }
        } else {
            NavigationView {
                contentList
            }
        }
    }
    
    private var contentList: some View {
        List {
            NavigationLink {
                QRCodePage()
            } label: {
                Label("Fudan QR Code", systemImage: "qrcode")
            }
            
            NavigationLink {
                if AuthDelegate.shared.isLogged {
                    TreeholePage()
                } else {
                    TreeholeWelcomePage()
                }
            } label: {
                Label("Tree Hole", systemImage: "text.bubble")
            }
            
            NavigationLink {
                if AuthDelegate.shared.isLogged {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
