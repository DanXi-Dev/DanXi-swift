import SwiftUI

struct HoleDetailPage: View {
    @StateObject var viewModel: HoleDetailViewModel
    @State var showReplyPage = false
    @State var scrollTarget: Int?
    
    init(hole: THHole) {
        self._viewModel = StateObject(wrappedValue: HoleDetailViewModel(hole: hole))
    }
    
    init(hole: THHole, floors: [THFloor]) { // for preview purpose
        let viewModel = HoleDetailViewModel(hole: hole)
        viewModel.floors = floors
        viewModel.endReached = true
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    init(holeId: Int) { // init from hole ID, load info afterwards
        self._viewModel = StateObject(wrappedValue: HoleDetailViewModel(holeId: holeId))
    }
    
    init(targetFloorId: Int) { // init from floor ID, scroll to that floor
        self._viewModel = StateObject(wrappedValue: HoleDetailViewModel(targetFloorId: targetFloorId))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    if let hole = viewModel.hole {
                        ForEach(viewModel.filteredFloors) { floor in
                            FloorView(floor: floor,
                                      isPoster: floor.posterName == hole.firstFloor.posterName,
                                      model: viewModel,
                                      proxy: proxy)
                            .task {
                                if floor == viewModel.floors.last {
                                    await viewModel.loadMoreFloors()
                                }
                            }
                            .id(floor.id)
                        }
                    }
                } header: {
                    if let hole = viewModel.hole {
                        TagListNavigation(tags: hole.tags)
                            .textCase(nil)
                    }
                } footer: {
                    if !viewModel.endReached {
                        ListLoadingView(loading: $viewModel.listLoading,
                                        errorDescription: viewModel.listError.description,
                                        action: viewModel.loadMoreFloors)
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle(viewModel.hole == nil ? "Loading" : "#\(String(viewModel.hole!.id))")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbar
                }
            }
            // access scroll view proxy from outside, i.e., toolbar
            .onChange(of: scrollTarget, perform: { target in
                if let target = target {
                    scrollTarget = nil
                    withAnimation {
                        proxy.scrollTo(target)
                    }
                }
            })
            .task {
                await viewModel.initialLoad(proxy: proxy)
            }
            .alert(viewModel.errorInfo.title, isPresented: $viewModel.errorPresenting) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorInfo.description)
            }
        }
    }
    
    @ViewBuilder
    var toolbar: some View {
        if let hole = viewModel.hole {
            Button {
                Task { @MainActor in
                    await viewModel.toggleFavorites()
                }
            } label: {
                Image(systemName: viewModel.favorited ? "star.fill" : "star")
            }
            
            Button(action: { showReplyPage = true }) {
                Image(systemName: "arrowshape.turn.up.left")
            }
            .sheet(isPresented: $showReplyPage) {
                ReplyPage(
                    holeId: hole.id,
                    content: "")
            }
            
            Menu {
                Picker("Filter Options", selection: $viewModel.filterOption) {
                    Label("Show All", systemImage: "list.bullet")
                        .tag(HoleDetailViewModel.FilterOptions.all)
                    
                    Label("Show OP Only", systemImage: "person.fill")
                        .tag(HoleDetailViewModel.FilterOptions.posterOnly)
                }
                
                Button {
                    Task {
                        await viewModel.loadToBottom()
                        scrollTarget = viewModel.floors.last?.id
                    }
                } label: {
                    Label("Navigate to Bottom", systemImage: "arrow.down.to.line")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        
    }
}

struct PostPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HoleDetailPage(hole: PreviewDecode.decodeObj(name: "hole")!, floors: PreviewDecode.decodeList(name: "floor-list"))
        }
    }
}

