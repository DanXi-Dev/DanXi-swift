import SwiftUI
import FudanUI
import ViewUtils

struct SplitNavigation: View {
    @StateObject private var navigator = AppNavigator(isCompactMode: false)
    @State private var contentPath = NavigationPath()
    @State private var detailPath = NavigationPath()
    
    func appendContent(item: any Hashable) {
        contentPath.append(item)
    }
    
    func appendDetail(item: any Hashable, replace: Bool) {
        if replace {
            detailPath.removeLast(detailPath.count)
        }
        detailPath.append(item)
    }
    
    var body: some View {
//        NavigationSplitView {
//            List {
//                Text("Campus.Tab")
//            }
//            .navigationTitle("DanXi")
//        } content: {
//            NavigationStack(path: $contentPath) {
//                CampusHome()
//                    .environmentObject(navigator)
//            }
//            .onReceive(navigator.contentSubject) { item in
//                appendContent(item: item)
//            }
//        } detail: {
//            NavigationStack(path: $detailPath) {
//                CampusDetail()
//                    .environmentObject(navigator)
//            }
//            .onReceive(navigator.detailSubject) { item, replace in
//                appendDetail(item: item, replace: replace)
//            }
//        }
        
        NavigationSplitView {
            List {
                Text("Forum")
            }
            .navigationTitle("DanXi")
        } content: {
//            ForumContent()
            CampusContent()
                .environmentObject(navigator)
        } detail: {
            CampusDetail()
                .environmentObject(navigator)
        }
    }
}

#Preview {
    SplitNavigation()
}
