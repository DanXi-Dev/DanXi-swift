import SwiftUI
import WrappingHStack

struct THDetailPage: View {
    @StateObject var viewModel: THDetailModel
    @State var showReplyPage = false
    @State var showManagementPage = false
    @State var showHideAlert = false
    var contextPreviewMode = false
    
    @Environment(\.previewMode) var previewMode
    
    init(hole: THHole, floorId: Int? = nil, floors: [THFloor] = []) {
        let viewModel = THDetailModel(hole: hole, floorId: floorId)
        if !floors.isEmpty { // preview purpose
            viewModel.floors = floors
            viewModel.endReached = true
        }
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    init(holeId: Int, floorId: Int? = nil) {
        self._viewModel = StateObject(wrappedValue:
                                        THDetailModel(holeId: holeId, floorId: floorId))
    }
    
    init(floorId: Int) { // init from floor ID, scroll to that floor
        self._viewModel = StateObject(wrappedValue: THDetailModel(floorId: floorId))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $viewModel.deleteSelection) {
                Section {
                    // MARK: Body (floor list)
                    floors(proxy)
                } header: {
                    // MARK: Header (tags)
                    tags
                } footer: {
                    // MARK: Footer
                    if !viewModel.endReached {
                        LoadingFooter(loading: $viewModel.listLoading,
                                      errorDescription: viewModel.listError,
                                      action: viewModel.loadMoreFloors)
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle(viewModel.hole == nil ? "Loading" : "#\(String(viewModel.hole!.id))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbar
                }
                
                ToolbarItem(placement: .status) {
                    BatchDeleteBar()
                        .environmentObject(viewModel)
                }
            }
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
            .sheet(isPresented: $showManagementPage, content: {
                if let hole = viewModel.hole {
                    THInfoSheet(holeId: hole.id,
                                 divisionId: hole.divisionId,
                                 tags: hole.tags.map(\.name),
                                 hidden: hole.hidden)
                } else {
                    ProgressView()
                }
            })
            .alert("Error", isPresented: $viewModel.errorPresenting) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorInfo)
            }
            .alert("Confirm Delete Post", isPresented: $showHideAlert) {
                Button("Confirm", role: .destructive) {
                    Task {
                        if let hole = viewModel.hole {
                            try await TreeholeRequests.deleteHole(holeId: hole.id)
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will affect all replies of this post")
            }
            .loadingOverlay(loading: viewModel.loadingToBottom, prompt: "Loading")
            .interactable(true)
        }
    }
    
    @ViewBuilder
    var tags: some View {
        if !previewMode {
            if let hole = viewModel.hole {
                // FIXME: use WrappingHStack and prevent navigation issue (WrappingHStack content is outside view hierarchy)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(hole.tags) { tag in
                            NavigationLink(value: tag) {
                                THTagView(tag: tag)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
    }
    
    @ViewBuilder
    func floors(_ proxy: ScrollViewProxy) -> some View {
        if let hole = viewModel.hole {
            ForEach(viewModel.filteredFloors, id: \.listId) { floor in
                THFloorView(floor: floor,
                          isPoster: floor.posterName == hole.firstFloor.posterName,
                          model: viewModel,
                          proxy: proxy)
                .task {
                    if floor == viewModel.filteredFloors.last && !viewModel.endReached {
                        await viewModel.loadMoreFloors()
                    }
                }
                .id(floor.id)
                .tag(floor)
            }
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
                THReplySheet(
                    holeId: hole.id,
                    content: "",
                    endReached: $viewModel.endReached)
            }
            
            Menu {
                Picker("Filter Options", selection: $viewModel.filterOption) {
                    Label("Show All", systemImage: "list.bullet")
                        .tag(THDetailModel.FilterOptions.all)
                    
                    Label("Show OP Only", systemImage: "person.fill")
                        .tag(THDetailModel.FilterOptions.posterOnly)
                }
                
                Button {
                    Task {
                        await viewModel.loadToBottom()
                    }
                } label: {
                    Label("Navigate to Bottom", systemImage: "arrow.down.to.line")
                }
                
                if UserStore.shared.isAdmin {
                    Divider()
                    
                    if !hole.hidden {
                        Button {
                            showHideAlert = true
                        } label: {
                            Label("Hide Hole", systemImage: "eye.slash.fill")
                        }
                    }
                    
                    Button {
                        showManagementPage = true
                    } label: {
                        Label("Edit Post Info", systemImage: "info.circle")
                    }
                    
                    EditButton()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

struct BatchDeleteBar: View {
    @Environment(\.editMode) var editMode
    @EnvironmentObject var viewModel: THDetailModel
    
    var body: some View {
        if editMode?.wrappedValue.isEditing == true && !viewModel.deleteSelection.isEmpty {
            Button(role: .destructive) {
                let floors = Array(viewModel.deleteSelection)
                Task {
                    await viewModel.deleteSelected(floors)
                }
                
                withAnimation {
                    editMode?.wrappedValue = .inactive
                }
            } label: {
                Label("Delete selected floors", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
                    .foregroundColor(.red)
            }
        } else {
            EmptyView()
        }
    }
}

struct THDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            THDetailPage(hole: Bundle.main.decodeData("hole"),
                           floors: Bundle.main.decodeData("floor-list"))
        }
    }
}
