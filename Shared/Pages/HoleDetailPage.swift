import SwiftUI

struct HoleDetailPage: View {
    @ObservedObject var dataModel = TreeholeDataModel.shared
    @StateObject var viewModel: HoleDetailViewModel
    @State var showReplyPage = false
    @State var showManagementPage = false
    @State var showHideAlert = false
    
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
                        if viewModel.floors.isEmpty {
                            // prefetched floors, to be replaced after reload prefetch is done
                            ForEach(hole.floors) { floor in
                                FloorView(floor: floor,
                                          isPoster: floor.posterName == hole.firstFloor.posterName,
                                          model: viewModel,
                                          proxy: proxy)
                                .task {
                                    if floor == viewModel.filteredFloors.last {
                                        await viewModel.loadMoreFloors()
                                    }
                                }
                                .id(floor.id)
                            }
                        } else {
                            ForEach(viewModel.filteredFloors) { floor in
                                FloorView(floor: floor,
                                          isPoster: floor.posterName == hole.firstFloor.posterName,
                                          model: viewModel,
                                          proxy: proxy)
                                .task {
                                    if floor == viewModel.filteredFloors.last {
                                        await viewModel.loadMoreFloors()
                                    }
                                }
                                .id(floor.id)
                            }
                        }
                    }
                } header: {
                    if let hole = viewModel.hole {
                        TagList(hole.tags, navigation: true)
                    }
                } footer: {
                    if !viewModel.endReached {
                        LoadingFooter(loading: $viewModel.listLoading,
                                      errorDescription: viewModel.listError,
                                      action: viewModel.loadMoreFloors)
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle(viewModel.hole == nil ? "Loading" : "#\(String(viewModel.hole!.id))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbar
                }
            }
            .sheet(isPresented: $showManagementPage, content: {
                if let hole = viewModel.hole {
                    EditInfoForm(holeId: hole.id,
                                 divisionId: hole.divisionId,
                                 tags: hole.tags.map(\.name))
                } else {
                    ProgressView()
                }
            })
            // access scroll view proxy from outside, i.e., toolbar
            .onChange(of: viewModel.scrollTarget, perform: { target in
                withAnimation {
                    proxy.scrollTo(target)
                }
                viewModel.scrollTarget = -1 // reset scroll target, in case that the same target may be scrolled again
            })
            .task {
                await viewModel.initialLoad()
            }
            .alert(viewModel.errorTitle, isPresented: $viewModel.errorPresenting) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorInfo)
            }
            .alert("Confirm Delete Post", isPresented: $showHideAlert) {
                Button("Confirm", role: .destructive) {
                    Task {
                        if let hole = viewModel.hole {
                            try await DXNetworks.shared.deleteHole(holeId: hole.id)
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will affect all replies of this post")
            }
            .loadingOverlay(loading: viewModel.loadingToBottom, prompt: "Loading")
        }
    }
    
    @ViewBuilder
    var toolbar: some View {
        if let hole = viewModel.hole {
            Button {
                viewModel.toggleFavorites()
            } label: {
                Image(systemName: viewModel.favorited ? "star.fill" : "star")
            }
            
            Button(action: { showReplyPage = true }) {
                Image(systemName: "arrowshape.turn.up.left")
            }
            .sheet(isPresented: $showReplyPage) {
                ReplyForm(
                    holeId: hole.id,
                    content: "",
                    endReached: $viewModel.endReached)
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
                    }
                } label: {
                    Label("Navigate to Bottom", systemImage: "arrow.down.to.line")
                }
                
                if dataModel.user?.isAdmin ?? false {
                    Divider()
                    
                    Button {
                        showHideAlert = true
                    } label: {
                        Label("Hide Hole", systemImage: "eye.slash.fill")
                    }
                    
                    Button {
                        showManagementPage = true
                    } label: {
                        Label("Edit Tags & Division", systemImage: "info.circle")
                    }
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

