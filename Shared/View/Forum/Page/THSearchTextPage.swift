import SwiftUI

struct THSearchTextPage: View {
    let keyword: String
    @State private var endReached = false
    @State var floors: [THFloor] = []
    
    @State var loading = false
    @State var errorInfo = ""
    
    func loadMoreFloors() async {
        do {
            loading = true
            defer { loading = false }
            let newFloors = try await THRequests.searchKeyword(keyword: keyword, startFloor: floors.count)
            endReached = newFloors.isEmpty
            let ids = floors.map(\.id)
            floors.append(contentsOf: newFloors.filter { !ids.contains($0.id) })
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    var body: some View {
        List {
            ForEach(floors) { floor in
                NavigationPlainLink(value: floor) {
                    THFloorView(floor: floor)
                        .interactable(false)
                }
                .task {
                    if floor == floors.last {
                        await loadMoreFloors()
                    }
                }
            }
            
            if !endReached {
                LoadingFooter(loading: $loading,
                              errorDescription: errorInfo,
                              action: loadMoreFloors)
            }
        }
        .listStyle(.inset)
        .task {
            if floors.isEmpty {
                await loadMoreFloors()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search Result")
    }
}

struct THSearchTextPage_Previews: PreviewProvider {
    static var previews: some View {
        THSearchTextPage(keyword: "Test")
    }
}
