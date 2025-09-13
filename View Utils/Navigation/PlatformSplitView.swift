#if !os(watchOS)
import SwiftUI
import SwiftUIIntrospect

/**
 A `NavigationSplitView` wrapper on macOS to display the translucent sidebar.
 
 On macOS, the app needs a translucent sidebar. That can only be achieved by setting the `primaryBackgroundStyle` field of `UISplitViewController`,
 which is not available in SwiftUI. This view leverages the SwiftUI Introspect framework to manipulate the underlying `UISplitViewController`.
 */
public struct PlatformSplitView<Sidebar: View, Content: View, Detail: View>: View {
    private let sidebar: () -> Sidebar
    private let content: () -> Content
    private let detail: () -> Detail
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    public init(@ViewBuilder sidebar: @escaping () -> Sidebar, @ViewBuilder content: @escaping () -> Content, @ViewBuilder detail: @escaping () -> Detail) {
        self.sidebar = sidebar
        self.content = content
        self.detail = detail
    }
    
    public var body: some View {
        #if targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *) {
            NavigationSplitView {
                sidebar()
            } content: {
                content()
            } detail: {
                detail()
            }
        } else {
            NavigationSplitView {
                EmptyView()
            } content: {
                content()
            } detail: {
                detail()
            }
            .introspect(.navigationSplitView, on: .iOS(.v16, .v17, .v18)) { splitViewController in
                let sidebarController = UIHostingController(rootView: sidebar())
                sidebarController.view.backgroundColor = .clear
                splitViewController.viewControllers[0] = sidebarController
                
                splitViewController.primaryBackgroundStyle = .sidebar
                splitViewController.preferredDisplayMode = .twoBesideSecondary
                splitViewController.presentsWithGesture = false
            }
        }
        #else
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar()
        } content: {
            content()
        } detail: {
            detail()
        }
        #endif
        
    }
}
#endif
