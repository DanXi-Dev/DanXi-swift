import SwiftUI
import Foundation

struct TreeholePage: View {
    @ObservedObject var model = treeholeDataModel
    @StateObject var viewModel = TreeholeViewModel()
    
    @State var searchText = ""
    @State var searchSubmitted = false
    
    @State var showEditPage = false
    
    
    var body: some View {
        TreeholeSearchable(searchText: $searchText, searchSubmitted: $searchSubmitted)
            .environmentObject(viewModel)
            .task {
                await viewModel.initialLoad()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .onSubmit(of: .search) {
                searchSubmitted = true
            }
            .navigationTitle(viewModel.currentDivision.name)
            .alert(viewModel.errorInfo.title, isPresented: $viewModel.errorPresenting) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorInfo.description)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ToolbarMenu() // menu item can't perform navigation, this is a workaround
                    
                    Button(action: { showEditPage = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                    .sheet(isPresented: $showEditPage) {
                        EditPage(divisionId: viewModel.currentDivisionId, showNewPostPage: $showEditPage)
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
    
    var body: some View {
        Menu {
            Button {
                self.navigationTarget = AnyView(FavoritesPage())
                self.isActive = true
            } label: {
                Label("favorites", systemImage: "star")
            }
            
            Button {
                self.navigationTarget = AnyView(TagsPage())
                self.isActive = true
            } label: {
                Label("tags", systemImage: "tag")
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
        NavigationView {
            TreeholePage()
        }
    }
}
