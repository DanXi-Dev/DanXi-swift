import SwiftUI

struct TreeholeSearch: View {
    @ObservedObject var model = TreeholeDataModel.shared
    @Binding var searchText: String
    @Binding var searchSubmitted: Bool
    @EnvironmentObject var viewModel: TreeholeViewModel
    @AppStorage("treehole-search-history") var searchHistory: [String] = []
    
    private var filteredTags: [THTag] {
        return model.tags.filter { $0.name.contains(searchText) }
    }
    
    func appendHistory(_ content: String) {
        if searchHistory.contains(content) {
            return
        }

        searchHistory.append(content)
    }
    
    struct SearchHistoryEntry: Identifiable {
        let id = UUID()
        let content: String
    }
    
    private var searchHistoryIdentifiable: [SearchHistoryEntry] {
        return searchHistory.map { history in
            SearchHistoryEntry(content: history)
        }
    }
    
    var body: some View {
        List {
            if !searchText.isEmpty { // search tag
                Section("Search Text") {
                    NavigationLink(destination: SearchTextPage(keyword: searchText)) {
                        Label(searchText, systemImage: "magnifyingglass")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        appendHistory(searchText)
                    })
                }
            } else if !searchHistory.isEmpty { // search history
                Section {
                    ForEach(searchHistoryIdentifiable) { history in
                        Label(history.content, systemImage: "clock")
                            .onTapGesture {
                                searchText = history.content
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
            
            // navigate to hole by ID, don't assume hole id length
            if searchText ~= #"^#[0-9]+$"#, let holeId = Int(searchText.dropFirst(1)) {
                Section("Jump to Hole") {
                    NavigationLink(destination: HoleDetailPage(holeId: holeId)) {
                        Label(searchText, systemImage: "arrow.right.square")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        appendHistory(searchText)
                    })
                }
            }
            
            // navigate to floor by ID, don't assume floor id length
            if searchText ~= #"^##[0-9]+$"#, let floorId = Int(searchText.dropFirst(2)) {
                Section("Jump to Floor") {
                    NavigationLink(destination: HoleDetailPage(targetFloorId: floorId)) {
                        Label(searchText, systemImage: "arrow.right.square")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        appendHistory(searchText)
                    })
                }
            }
            
            // search tag
            if !filteredTags.isEmpty {
                Section("Tags") {
                    ForEach(filteredTags) { tag in
                        NavigationLink(destination: SearchTagPage(tagname: tag.name, divisionId: viewModel.currentDivisionId)) {
                            Label(tag.name, systemImage: "tag")
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            appendHistory(searchText)
                        })
                    }
                }
            }
        }
        .listStyle(.grouped)
    }
}

struct TreeholeSearch_Previews: PreviewProvider {
    static var previews: some View {
        TreeholeSearch(searchText: .constant(""), searchSubmitted: .constant(false))
    }
}
