import SwiftUI
import WrappingHStack

struct THHolePage: View {
    @StateObject var model: THHoleModel
    
    init(_ hole: THHole) {
        self._model = StateObject(wrappedValue: THHoleModel(hole: hole))
    }
    
    init(_ model: THHoleModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    THHoleTags(tags: model.hole.tags)
                        .listRowSeparator(.hidden, edges: .top)
                    
                    ForEach(model.filteredFloors) { floor in
                        THComplexFloor(floor, highlighted: model.initialScroll == floor.id)
                            .task {
                                if floor == model.filteredFloors.last {
                                    await model.loadMoreFloors()
                                }
                            }
                    }
                    
                    if !model.endReached {
                        LoadingFooter(loading: $model.loading,
                                      errorDescription: (model.loadingError?.localizedDescription ?? ""),
                                      action: model.loadAllFloors)

                    }
                }
                .task {
                    if model.floors.isEmpty {
                        await model.loadMoreFloors()
                    }
                }
                .onAppear {
                    if model.scrollTarget != -1 {
                        proxy.scrollTo(model.scrollTarget, anchor: .top)
                        model.scrollTarget = -1 // reset scroll target, so that may scroll to the same target for multiple times
                    }
                }
                .onChange(of: model.scrollTarget) { target in
                    if target > 0 {
                        withAnimation {
                            // SwiftUI bug: App may crash, ref: https://useyourloaf.com/blog/swiftui-scrollviewproxy-crash/
                            proxy.scrollTo(target, anchor: .top)
                        }
                        model.scrollTarget = -1 // reset scroll target, so that may scroll to the same target for multiple times
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("#\(String(model.hole.id))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    THHoleToolbar()
                }
                
                ToolbarItem(placement: .bottomBar) {
                    THHoleBottomBar()
                }
            }
            .environmentObject(model)
        }
    }
}

fileprivate struct THHoleToolbar: View {
    @EnvironmentObject var model: THHoleModel
    @Environment(\.editMode) var editMode
    
    @State var showDeleteAlert = false
    @State var showEditSheet = false
    @State var showReplySheet = false
    
    var body: some View {
        Group {
            replyButton
            favoriteButton
            menu
        }
    }
    
    private var replyButton: some View {
        Button {
            showReplySheet = true
        } label: {
            Image(systemName: "arrowshape.turn.up.left")
        }
        .sheet(isPresented: $showReplySheet) {
            THReplySheet()
        }
    }
    
    private var favoriteButton: some View {
        AsyncButton {
            try await model.toggleFavorite()
            haptic()
        } label: {
            Image(systemName: model.isFavorite ? "star.fill" : "star")
        }
    }
    
    private var menu: some View {
        Menu {
            Picker("Filter Options", selection: $model.filterOption) {
                Label("Show All", systemImage: "list.bullet")
                    .tag(THHoleModel.FilterOptions.all)
                
                Label("Show OP Only", systemImage: "person.fill")
                    .tag(THHoleModel.FilterOptions.posterOnly)
            }
            
            AsyncButton {
                await model.loadAllFloors()
            } label: {
                Label("Navigate to Bottom", systemImage: "arrow.down.to.line")
            }
            
            if DXModel.shared.isAdmin {
                Divider()
                
                if !model.hole.hidden {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Label("Hide Hole", systemImage: "eye.slash.fill")
                    }
                }
                
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Post Info", systemImage: "info.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .sheet(isPresented: $showEditSheet) {
            THHoleEditSheet(model.hole)
        }
        .alert("Confirm Delete Post", isPresented: $showDeleteAlert) {
            Button("Confirm", role: .destructive) {
                Task {
                    try await model.deleteHole()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will affect all replies of this post")
        }
    }
}

struct THHoleTags: View {
    @EnvironmentObject var navigationModel: THNavigationModel
    let tags: [THTag]
    
    var body: some View {
        WrappingHStack(alignment: .leading) {
            ForEach(tags) { tag in
                Button {
                    navigationModel.path.append(tag)
                } label: {
                    THTagView(tag)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

fileprivate struct THHoleBottomBar: View {
    @EnvironmentObject var model: THHoleModel
    
    var body: some View {
        if model.showBottomBar {
            Button {
                model.filterOption = .all
            } label: {
                Label("Show All Floors", systemImage: "bubble.left.and.bubble.right")
                    .labelStyle(.titleAndIcon)
            }
        }
    }
}
