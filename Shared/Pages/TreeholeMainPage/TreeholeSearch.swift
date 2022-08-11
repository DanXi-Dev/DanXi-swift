import SwiftUI

struct TreeholeSearch: View {
    @ObservedObject var model = treeholeDataModel
    @Binding var searchText: String
    @Binding var searchSubmitted: Bool
    @EnvironmentObject var viewModel: TreeholeViewModel
    
    private var filteredTags: [THTag] {
        return model.tags.filter { $0.name.contains(searchText) }
    }
    
    var body: some View {
        List {
            if !searchText.isEmpty {
                Section("Search Text") {
                    NavigationLink(destination: SearchTextPage(keyword: searchText)) {
                        Label(searchText, systemImage: "magnifyingglass")
                    }
                }
            } else {
                Section("Search History") {
                    Text("") // TODO: search history
                }
            }
            
            // navigate to hole by ID, don't assume hole id length
            if searchText ~= #"^#[0-9]+$"#, let holeId = Int(searchText.dropFirst(1)) {
                Section("Jump to Hole") {
                    NavigationLink(destination: HoleDetailPage(holeId: holeId)) {
                        Label(searchText, systemImage: "arrow.right.square")
                    }
                }
            }
            
            // navigate to floor by ID, don't assume floor id length
            if searchText ~= #"^##[0-9]+$"#, let floorId = Int(searchText.dropFirst(2)) {
                Section("Jump to Floor") {
                    NavigationLink(destination: HoleDetailPage(targetFloorId: floorId)) {
                        Label(searchText, systemImage: "arrow.right.square")
                    }
                }
            }
            
            if !filteredTags.isEmpty {
                Section("Tags") {
                    ForEach(filteredTags) { tag in
                        NavigationLink(destination: SearchTagPage(tagname: tag.name, divisionId: viewModel.currentDivisionId)) {
                            Label(tag.name, systemImage: "tag")
                        }
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
