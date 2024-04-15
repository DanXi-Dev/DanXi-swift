import SwiftUI
import ViewUtils

struct THSearchPage: View {
    @EnvironmentObject private var model: THSearchModel
    @EnvironmentObject private var navigator: AppNavigator
    
    var body: some View {
        THBackgroundList {
            if !model.history.isEmpty && model.searchText.isEmpty {
                searchHistory
            }
            
            if let matchFloor = model.matchFloor {
                DetailLink(value: THHoleLoader(floorId: matchFloor)) {
                    model.appendHistory(model.searchText)
                } label: {
                    Label("##\(String(matchFloor))", systemImage: "arrow.right.square")
                }
            }
            
            if let matchHole = model.matchHole {
                DetailLink(value: THHoleLoader(holeId: matchHole)) {
                    model.appendHistory(model.searchText)
                } label: {
                    Label("#\(String(matchHole))", systemImage: "arrow.right.square")
                }
            }
            
            ForEach(model.matchTags) { tag in
                ContentLink(value: tag) {
                    Label(tag.name, systemImage: "tag")
                }
            }
        }
        .onChange(of: model.navLoader) { loader in
            if let loader = loader {
                navigator.pushDetail(value: loader, replace: true)
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
    @EnvironmentObject private var model: THSearchModel
    
    var body: some View {
        List {
            AsyncCollection { floors in
                try await THRequests.searchKeyword(keyword: model.searchText, startFloor: floors.count)
            } content: { floor in
                DetailLink(value: THHoleLoader(floor)) {
                    THSimpleFloor(floor: floor)
                }
            }
        }
        .listStyle(.inset)
    }
}
