import SwiftUI

struct ContentView: View {
    @ObservedObject var authDelegate = AuthDelegate.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                    
                    LinkView(url: "https://canvas.fduhole.com", text: "Canvas", icon: "paintbrush.pointed")
                    
                    LinkView(url: "https://fdu-hotpot.top", text: "FDU Hotpot", icon: "figure.run")
                } else {
                    // TODO: refine this section
                    Text("Not Logged In")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                NavigationLink {
                    SettingsPage()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                
                NavigationLink {
                    AboutPage()
                } label: {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("DanXi")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthDelegate.shared.isLogged = true
        
        return ContentView()
    }
}
