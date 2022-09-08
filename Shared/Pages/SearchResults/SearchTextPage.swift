import SwiftUI

struct SearchTextPage: View {
    let keyword: String
    @State private var endReached = false
    @State var floors: [THFloor] = []
    
    @State var loading = false
    @State var errorInfo = ErrorInfo()
    
    func loadMoreFloors() async {
        do {
            loading = true
            defer { loading = false }
            let newFloors = try await NetworkRequests.shared.searchKeyword(keyword: keyword, startFloor: floors.count)
            endReached = newFloors.isEmpty
            floors.append(contentsOf: newFloors)
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            errorInfo = error.localizedErrorDescription
        } catch {
            errorInfo = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
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
                    LoadingFooter(loading: $loading,
                                    errorDescription: errorInfo.description,
                                    action: loadMoreFloors)
                }
            }
        }
        .task {
            if floors.isEmpty {
                await loadMoreFloors()
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
