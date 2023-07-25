import SwiftUI

struct THSearchPage: View {
    @EnvironmentObject private var model: THSearchModel
    @EnvironmentObject private var navModel: THNavigator
    
    var body: some View {
        THBackgroundList {
            if !model.history.isEmpty && model.searchText.isEmpty {
                searchHistory
            }
            
            if let matchFloor = model.matchFloor {
                Button {
                    model.appendHistory(model.searchText)
                    navModel.path.append(THHoleLoader(floorId: matchFloor))
                } label: {
                    Label("##\(String(matchFloor))", systemImage: "arrow.right.square")
                }
            }
            
            if let matchHole = model.matchHole {
                Button {
                    model.appendHistory(model.searchText)
                    navModel.path.append(THHoleLoader(holeId: matchHole))
                } label: {
                    Label("#\(String(matchHole))", systemImage: "arrow.right.square")
                }
            }
            
            ForEach(model.matchTags) { tag in
                NavigationLink(value: tag) {
                    Label(tag.name, systemImage: "tag")
                }
            }
        }
        .onChange(of: model.navLoader) { loader in
            if let loader = loader {
                navModel.path.append(loader)
                model.navLoader = nil // reset loader, prevent not be able to jump to the same destination the next time
            }
        }
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
            .swipeActions {
                Button(role: .destructive) {
                    model.removeHistory(history)
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}


struct THSearchResultPage: View {
    @EnvironmentObject var navigationModel: THNavigator
    @EnvironmentObject var model: THSearchModel
    
    var body: some View {
        List {
            AsyncCollection { floors in
                try await THRequests.searchKeyword(keyword: model.searchText, startFloor: floors.count)
            } content: { floor in
                NavigationListRow(value: THHoleLoader(floor)) {
                    THSimpleFloor(floor: floor)
                }
            }
        }
        .listStyle(.inset)
    }
}
