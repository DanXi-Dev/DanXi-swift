import SwiftUI
import SwiftUIX

struct THSearchPage: View {
    @EnvironmentObject var router: NavigationRouter
    @Binding var searchText: String
    @Binding var searchSubmitted: Bool
    @AppStorage("treehole-search-history") var searchHistory: [String] = []
    
    private var filteredTags: [THTag] {
        return THStore.shared.tags.filter { $0.name.contains(searchText) }
    }
    
    func appendHistory(_ content: String) {
        if searchHistory.contains(content) {
            return
        }

        searchHistory.insert(content, at: 0)
    }
    
    var body: some View {
        List {
            if !searchText.isEmpty { // search tag
                Section("Search Text") {
                    Button {
                        router.path.append(TreeholeStaticPages.searchText(keyword: searchText))
                        appendHistory(searchText)
                    } label: {
                        Label {
                            Text(searchText)
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "magnifyingglass")
                        }
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
                        Button(LocalizedStringKey("Clear History")) {
                            searchHistory = []
                        }
                    }
                }
            }
            
            // navigate to hole by ID
            if searchText ~= #"^#[0-9]+$"#, let holeId = Int(searchText.dropFirst(1)) {
                Section("Jump to Hole") {
                    NavigationLink {
                        THDetailPage(holeId: holeId)
                            .onAppear { appendHistory(searchText) }
                            .environmentObject(router)
                    } label: {
                        Label(searchText, systemImage: "arrow.right.square")
                    }
                }
            }
            
            // navigate to floor by ID, don't assume floor id length
            if searchText ~= #"^##[0-9]+$"#, let floorId = Int(searchText.dropFirst(2)) {
                Section("Jump to Floor") {
                    NavigationLink {
                        THDetailPage(floorId: floorId)
                            .onAppear { appendHistory(searchText) }
                            .environmentObject(router)
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
                            THSearchTagPage(tagname: tag.name)
                                .onAppear { appendHistory(searchText) }
                        } label: {
                            Label(tag.name, systemImage: "tag")
                        }
                    }
                }
            }
        }
        .onChange(of: searchSubmitted) { submit in
            if submit {
                appendHistory(searchText)
                router.path.append(TreeholeStaticPages.searchText(keyword: searchText))
            }
        }
    }
}
