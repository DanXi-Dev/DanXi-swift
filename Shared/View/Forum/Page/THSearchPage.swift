import SwiftUI

struct THSearchPage: View {
    @EnvironmentObject var model: THSearchModel
    
    var body: some View {
        List {
            if !model.history.isEmpty && model.searchText.isEmpty {
                searchHistory
            }
            
            if let matchFloor = model.matchFloor {
                NavigationLink(value: THHoleLoader(floorId: matchFloor)) {
                    Label("##\(String(matchFloor))", systemImage: "arrow.right.square")
                }
            }
            
            if let matchHole = model.matchHole {
                NavigationLink(value: THHoleLoader(holeId: matchHole)) {
                    Label("#\(String(matchHole))", systemImage: "arrow.right.square")
                }
            }
            
            ForEach(model.matchTags) { tag in
                NavigationLink(value: tag) {
                    Label(tag.name, systemImage: "tag")
                }
            }
        }
        .listStyle(.inset)
    }
    
    @ViewBuilder
    private var searchHistory: some View {
        HStack {
            Text("Recent Search")
            Spacer()
            Button {
                model.clearHistory()
            } label: {
                Text("Clear History")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.accentColor)
        }
        .font(.callout)
        .bold()
        .listRowSeparator(.hidden)
        
        ForEach(model.history, id: \.self) { history in
            Button {
                model.searchText = history
            } label: {
                Label {
                    Text(history)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: "clock")
                }
            }
        }
    }
}


struct THSearchResultPage: View {
    @EnvironmentObject var navigationModel: THNavigationModel
    @EnvironmentObject var model: THSearchModel
    
    @State var floors: [THFloor] = []
    
    @State var endReached = false
    @State var loading = false
    @State var loadingError: Error?
    
    func loadMoreFloors() async {
        do {
            loading = true
            defer { loading = false }
            let newFloors = try await THRequests.searchKeyword(keyword: model.searchText, startFloor: floors.count)
            endReached = newFloors.isEmpty
            let ids = floors.map(\.id)
            floors.append(contentsOf: newFloors.filter { !ids.contains($0.id) })
        } catch {
            loadingError = error
        }
    }
    
    var body: some View {
        List {
            ForEach(floors) { floor in
                NavigationListRow(value: THHoleLoader(floor)) {
                    THSimpleFloor(floor: floor)
                }
                .task {
                    if floor == floors.last {
                        await loadMoreFloors()
                    }
                }
            }
            
            if !endReached {
                LoadingFooter(loading: $loading,
                              errorDescription: loadingError?.localizedDescription ?? "") {
                    await loadMoreFloors()
                }
            }
        }
        .listStyle(.inset)
        .animation(.default, value: floors)
        .task {
            if floors.isEmpty {
                await loadMoreFloors()
            }
        }
    }
}
