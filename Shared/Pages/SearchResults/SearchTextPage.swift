import SwiftUI

struct SearchTextPage: View {
    let keyword: String
    @State private var endReached = false
    @State var floors: [THFloor] = []
    
    func loadMoreHoles() async {
        do {
            let newFloors = try await networks.searchKeyword(keyword: keyword, startFloor: floors.count)
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
                        .task {
                            if floor == floors.last {
                                await loadMoreHoles()
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
                            await loadMoreHoles()
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("search_result")
    }
}

struct SearchTextPage_Previews: PreviewProvider {
    static var previews: some View {
        SearchTextPage(keyword: "Test")
    }
}
