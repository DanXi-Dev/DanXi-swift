import SwiftUI

struct SearchTagPage: View {
    let tagname: String
    @State private var endReached = false
    @State var holes: [THHole] = []
    
    @State var loading = false
    @State var errorInfo = ""
    
    func loadMoreHoles() async {
        do {
            loading = true
            defer { loading = false }
            let newHoles = try await DXNetworks.shared.listHoleByTag(tagName: tagname, startTime: holes.last?.updateTime.ISO8601Format())
            endReached = newHoles.isEmpty
            holes.append(contentsOf: newHoles)
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(holes) { hole in
                    HoleView(hole: hole)
                        .task {
                            if hole == holes.last {
                                await loadMoreHoles()
                            }
                        }
                }
            } footer: {
                if !endReached {
                    if !endReached {
                        LoadingFooter(loading: $loading,
                                        errorDescription: errorInfo,
                                        action: loadMoreHoles)
                    }
                }
            }
        }
        .task {
            if holes.isEmpty {
                await loadMoreHoles()
            }
        }
        .listStyle(.grouped)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tagname)
    }
}

struct SearchTagPage_Previews: PreviewProvider {
    static var previews: some View {
        SearchTagPage(tagname: "test")
    }
}
