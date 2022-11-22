import SwiftUI

struct ContentView: View {
    @ObservedObject var authDelegate = AuthDelegate.shared
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
            
            
            Section {
                if authDelegate.isLogged {
                    NavigationLink {
                        TreeholePage()
                    } label: {
                        Label("Tree Hole", systemImage: "text.bubble")
                    }
                    
                    NavigationLink {
                        CourseMainPage()
                    } label: {
                        Label("Curriculum", systemImage: "books.vertical")
                    }
                    
                    Link(destination: URL(string: "https://canvas.fduhole.com")!) {
                        HStack {
                            Label {
                                Text("Canvas")
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "paintbrush.pointed")
                            }
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://fdu-hotpot.top")!) {
                        HStack {
                            Label {
                                Text("FDU Hotpot")
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "figure.run")
                            }
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.secondary)
                        }
                    }
                    
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
//        AuthDelegate.shared.isLogged = true
        
        return ContentView()
    }
}
