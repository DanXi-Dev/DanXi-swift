import SwiftUI

struct ContentView: View {
    @ObservedObject var authDelegate = AuthDelegate.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var showSettingPage = false
    
    var body: some View {
        NavigationSplitView {
            contentList
        } detail: {
            Text("Not Selected")
        }
    }
    
    private var contentList: some View {
        List {
            Section("Campus Services") {
                NavigationLink {
                    QRCodePage()
                } label: {
                    Label("Fudan QR Code", systemImage: "qrcode")
                }
            }
            
            Section("DanXi Services") {
                if authDelegate.isLogged {
                    NavigationLink {
                        TreeholePage()
                    } label: {
                        Label("Tree Hole", systemImage: "text.bubble")
                    }
                    
                    NavigationLink {
                        NavigationStack {
                            CourseMainPage()
                        }
                    } label: {
                        Label("Curriculum", systemImage: "books.vertical")
                    }
                    
                    listLink(url: "https://canvas.fduhole.com", text: "Canvas", icon: "paintbrush.pointed")
                    
                    listLink(url: "https://fdu-hotpot.top", text: "FDU Hotpot", icon: "figure.run")
                } else {
                    // TODO: refine this section
                    Text("Not Logged In")
                        .foregroundColor(.secondary)
                }
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
    
    private func listLink(url: String, text: LocalizedStringKey, icon: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Label {
                    Text(text)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: icon)
                }
                Spacer()
                Image(systemName: "link")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthDelegate.shared.isLogged = true
        
        return ContentView()
    }
}
