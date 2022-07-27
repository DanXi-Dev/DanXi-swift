import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        autoAppNavigation
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
