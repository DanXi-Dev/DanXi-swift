import SwiftUI

struct AppSidebarNavigation: View {
    @ObservedObject var model = TreeholeDataModel.shared

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
                        if (model.loggedIn) {
                            TreeholePage()
                        } else {
                            WelcomePage()
                        }
                    }
                } label: {
                    Label("Tree Hole", systemImage: "text.bubble")
                }
                
                NavigationLink(tag: NavigationItem.settings, selection: $selection) {
                    SettingsPage()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .navigationTitle("DanXi")
            
            EmptyView()
            EmptyView()
        }
        // FIXME: unable to simultaneously satisfy constraints on iPad (wide screen)
    }
}

// FIXME: This is a workaround to SwiftUI not exposing control APIs
// This relies on the navigation view using UISplitViewController as its backend
// Which may change and break things
extension UISplitViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()

        self.preferredDisplayMode = .twoOverSecondary
        self.preferredSplitBehavior = .automatic
    }
}

struct AppSidebarNavigation_Previews: PreviewProvider {
    
    static var previews: some View {
        AppSidebarNavigation()
            .previewDevice("iPad Pro (12.9-inch) (5th generation)")
            .previewInterfaceOrientation(.landscapeRight)
    }
}
