import SwiftUI

struct SearchPage: View {
    @ObservedObject var model = TreeholeDataModel.shared
    @Binding var searchText: String
    @Binding var searchSubmitted: Bool
    @AppStorage("treehole-search-history") var searchHistory: [String] = []
    
    @State var tagNavActive = false
    @State var textNavActive = false
    @State var floorNavActive = false
    @State var holeNavActive = false
    
    private var filteredTags: [THTag] {
        return model.tags.filter { $0.name.contains(searchText) }
    }
    
    func appendHistory(_ content: String) {
        if searchHistory.contains(content) {
            return
        }

        searchHistory.append(content)
    }
    
    var body: some View {
        List {
            if !searchText.isEmpty { // search tag
                Section("Search Text") {
                    NavigationLink {
                        SearchTextPage(keyword: searchText)
                            .onAppear { appendHistory(searchText) }
                    } label: {
                        Label(searchText, systemImage: "magnifyingglass")
                    }
                }
            } else if !searchHistory.isEmpty { // search history
                Section {
                    ForEach(searchHistory, id: \.self) { history in
                        Button {
                            searchText = history
                        } label: {
                            Label {
                                Text(history)
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "clock")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Search History")
                        Spacer()
                        Button("Clear History") {
                            searchHistory = []
                        }
                    }
                }
            }
            
            // navigate to hole by ID
            if searchText ~= #"^#[0-9]+$"#, let holeId = Int(searchText.dropFirst(1)) {
                Section("Jump to Hole") {
                    NavigationLink {
                        HoleDetailPage(holeId: holeId)
                            .onAppear { appendHistory(searchText) }
                    } label: {
                        Label(searchText, systemImage: "arrow.right.square")
                    }
                }
            }
            
            // navigate to floor by ID, don't assume floor id length
            if searchText ~= #"^##[0-9]+$"#, let floorId = Int(searchText.dropFirst(2)) {
                Section("Jump to Floor") {
                    NavigationLink {
                        HoleDetailPage(targetFloorId: floorId)
                            .onAppear { appendHistory(searchText) }
                    } label: {
                        Label(searchText, systemImage: "arrow.right.square")
                    }
                }
            }
            
            // search tag
            if !filteredTags.isEmpty {
                Section("Tags") {
                    ForEach(filteredTags) { tag in
                        NavigationLink {
                            SearchTagPage(tagname: tag.name, divisionId: nil)
                                .onAppear { appendHistory(searchText) }
                        } label: {
                            Label(tag.name, systemImage: "tag")
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        // navigate to search page when user click `search` in keyboard
        .background(NavigationLink("", destination: SearchTextPage(keyword: searchText),
                                   isActive: $searchSubmitted).opacity(0))
    }
}
