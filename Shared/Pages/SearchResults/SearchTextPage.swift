import SwiftUI

struct SearchTextPage: View {
    let keyword: String
    @State private var endReached = false
    @State var floors: [THFloor] = []
    
    func loadMoreFloors() async {
        do {
            let newFloors = try await NetworkRequests.shared.searchKeyword(keyword: keyword, startFloor: floors.count)
            endReached = newFloors.isEmpty
            floors.append(contentsOf: newFloors)
        } catch {
            print("DANXI-DEBUG: load more hole failed")
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(floors) { floor in
                    FloorView(floor: floor)
                        .background(NavigationLink("", destination: HoleDetailPage(targetFloorId: floor.id)).opacity(0))
                        .task {
                            if floor == floors.last {
                                await loadMoreFloors()
                            }
                        }
                }
            } footer: {
                if !endReached {
                    HStack() {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        if floors.isEmpty {
                            await loadMoreFloors()
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search Result")
    }
}

struct SearchTextPage_Previews: PreviewProvider {
    static var previews: some View {
        SearchTextPage(keyword: "Test")
    }
}
