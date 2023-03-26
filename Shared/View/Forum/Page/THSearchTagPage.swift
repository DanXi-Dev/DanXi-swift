import SwiftUI

struct THSearchTagPage: View {
    let tagname: String
    @State private var endReached = false
    @State var holes: [THHole] = []
    
    @State var loading = false
    @State var errorInfo = ""
    
    func loadMoreHoles() async {
        do {
            loading = true
            defer { loading = false }
            let newHoles = try await THRequests.listHoleByTag(tagName: tagname, startTime: holes.last?.updateTime.ISO8601Format())
            endReached = newHoles.isEmpty
            let ids = holes.map(\.id)
            holes.append(contentsOf: newHoles.filter { !ids.contains($0.id) })
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(holes) { hole in
                    THHoleView(hole: hole)
                        .task {
                            if hole == holes.last {
                                await loadMoreHoles()
                            }
                        }
                }
            } footer: {
                if !endReached {
                    LoadingFooter(loading: $loading,
                                    errorDescription: errorInfo,
                                    action: loadMoreHoles)
                }
            }
        }
        .listStyle(.inset)
        .task {
            if holes.isEmpty {
                await loadMoreHoles()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tagname)
    }
}
