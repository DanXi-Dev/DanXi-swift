import SwiftUI

struct AppSidebarNavigation: View {
    @EnvironmentObject var THdataModel: THDataModel

    enum NavigationItem {
        case treehole
        case settings
    }

    @State private var selection: NavigationItem? = .treehole
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(tag: NavigationItem.treehole, selection: $selection) {
                    Group {
                        if (THdataModel.isLogged) {
                            TreeHolePage()
                        } else {
                            THWelcomePage()
                        }
                    }
                } label: {
                    Label("treehole", systemImage: "text.bubble")
                }
                
                NavigationLink(tag: NavigationItem.settings, selection: $selection) {
                    SettingsPage()
                } label: {
                    Label("settings", systemImage: "gearshape")
                }
            }
            .navigationTitle("danxi")
            
            EmptyView()
            EmptyView()
        }
        
    }
}

struct AppSidebarNavigation_Previews: PreviewProvider {
    
    static var previews: some View {
        AppSidebarNavigation()
            .previewDevice("iPad Pro (12.9-inch) (5th generation)")
            .previewInterfaceOrientation(.landscapeRight)
    }
}
