import SwiftUI
import ViewUtils
import DanXiKit

struct SearchPage: View {
    @EnvironmentObject private var model: SearchModel
    @EnvironmentObject private var navigator: AppNavigator
    
    var body: some View {
        ForumList {
            if !model.history.isEmpty && model.searchText.isEmpty {
                searchHistory
            }
            
            if let matchFloor = model.matchFloor {
                DetailLink(value: HoleLoader(floorId: matchFloor)) {
                    model.appendHistory(model.searchText)
                } label: {
                    Label("##\(String(matchFloor))", systemImage: "arrow.right.square")
                }
            }
            
            if let matchHole = model.matchHole {
                DetailLink(value: HoleLoader(holeId: matchHole)) {
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
            #if targetEnvironment(macCatalyst)
            .listRowBackground(Color.clear)
            #endif
        }
        .onReceive(model.navigationPublisher) { loader in
            navigator.pushDetail(value: loader, replace: true)
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
        .listRowBackground(Color.clear)
        
        ForEach(model.history, id: \.self) { history in
            Button {
                model.searchText = history
            } label: {
                Text(history)
                    .foregroundColor(.primary)
            }
            .swipeActions {
                Button(role: .destructive) {
                    model.removeHistory(history)
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .listRowBackground(Color.clear)
    }
}

struct SearchResultPage: View {
    @EnvironmentObject private var model: SearchModel
    
    var body: some View {
        List {
            AsyncCollection { floors in
                try await ForumAPI.searchFloor(keyword: model.searchText, accurate: false, offset: floors.count)
            } content: { floor in
                DetailLink(value: HoleLoader(floor)) {
                    SimpleFloorView(floor: floor)
                }
            }
        }
        .listStyle(.inset)
        .watermark()
    }
}
