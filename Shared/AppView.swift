import SwiftUI

struct AppView: View {
    @StateObject var THaccountState = THAccountModel()
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    var body: some View {
        autoAppNavigation
            .environmentObject(THaccountState)
    }
    
    @ViewBuilder
    private var autoAppNavigation: some View {
        #if os(watchOS)
        AppTabNavigation()
        #elseif os(iOS)
        if horizontalSizeClass == .compact {
            AppTabNavigation()
        } else {
            AppSidebarNavigation()
        }
        #else
        AppSidebarNavigation()
        #endif
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