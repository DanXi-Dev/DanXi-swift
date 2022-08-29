import SwiftUI
import Foundation

struct TreeholePage: View {
    @ObservedObject var model = TreeholeDataModel.shared
    @StateObject var viewModel = TreeholeViewModel()
    
    @State var searchText = ""
    @State var searchSubmitted = false
    
    @State var showEditPage = false
    
    init() { }
    
    init(divisions: [THDivision], holes: [THHole]) { // preview purpose
        TreeholeDataModel.shared.divisions = divisions
        let viewModel = TreeholeViewModel()
        viewModel.currentDivision = divisions[0]
        viewModel.holes = holes
        viewModel.initFinished = true
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        InitLoadingView(loading: $viewModel.initLoading,
                        finished: $viewModel.initFinished,
                        errorDescription: viewModel.initError.description) {
            await viewModel.initialLoad()
        } content: {
            TreeholeSearchable(searchText: $searchText, searchSubmitted: $searchSubmitted)
                .environmentObject(viewModel)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
                .onSubmit(of: .search) {
                    searchSubmitted = true
                }
                .navigationTitle(viewModel.currentDivision.name)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        ToolbarMenu() // menu item can't perform navigation, this is a workaround
                            .environmentObject(viewModel)

                        Button(action: { showEditPage = true }) {
                            Image(systemName: "square.and.pencil")
                        }
                        .sheet(isPresented: $showEditPage) {
                            EditPage(divisionId: viewModel.currentDivisionId)
                        }
                    }
                }
        }
    }
}


// searchable delegation, switch between main view & search view based on searchbar status
struct TreeholeSearchable: View {
    @Environment(\.isSearching) var isSearching
    @Binding var searchText: String
    @Binding var searchSubmitted: Bool
    
    var body: some View {
        Group {
            if isSearching {
                TreeholeSearch(searchText: $searchText, searchSubmitted: $searchSubmitted)
            } else {
                TreeholeBrowse()
            }
        }
    }
}


struct ToolbarMenu: View {
    @State private var isActive = false // menu navigation workaround
    @State private var navigationTarget: AnyView?
    @EnvironmentObject var viewModel: TreeholeViewModel
    
    var body: some View {
        Menu {
            Button {
                self.navigationTarget = AnyView(FavoritesPage())
                self.isActive = true
            } label: {
                Label("Favorites", systemImage: "star")
            }
            
            Button {
                self.navigationTarget = AnyView(TagsPage())
                self.isActive = true
            } label: {
                Label("Tags", systemImage: "tag")
            }
            
            Picker("Sort Options", selection: $viewModel.sortOption) {
                Text("Last Updated")
                    .tag(TreeholeViewModel.SortOptions.byReplyTime)
                
                Text("Last Created")
                    .tag(TreeholeViewModel.SortOptions.byCreateTime)
            }
            .onChange(of: viewModel.sortOption) { newValue in
                Task {
                    await viewModel.switchSortOption(newValue)
                }
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .background(
            NavigationLink(destination: navigationTarget, isActive: $isActive) {
                EmptyView()
            })
    }
    
}

struct TreeholePage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                TreeholePage(divisions: PreviewDecode.decodeList(name: "divisions"), holes: PreviewDecode.decodeList(name: "hole-list"))
            }
            NavigationView {
                TreeholePage(divisions: PreviewDecode.decodeList(name: "divisions"), holes: PreviewDecode.decodeList(name: "hole-list"))
            }
            .preferredColorScheme(.dark)
        }
    }
}
