import SwiftUI

struct HoleDetailPage: View {
    @StateObject var viewModel: HoleDetailViewModel
    @State var showReplyPage = false
    
    init(hole: THHole) {
        self._viewModel = StateObject(wrappedValue: HoleDetailViewModel(hole: hole))
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
                        ForEach(viewModel.floors) { floor in
                            FloorView(floor: floor, isPoster: floor.posterName == hole.firstFloor.posterName )
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
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .task {
                            await viewModel.initialLoad(proxy: proxy)
                        }
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
            .alert(viewModel.errorInfo.title, isPresented: $viewModel.errorPresenting) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorInfo.description)
            }
        }
    }
    
    var toolbar: some View {
        Group {
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
                        showReplyPage: $showReplyPage,
                        content: "")
                }
            }
        }
    }
}

struct PostPage_Previews: PreviewProvider {
    static var previews: some View {
        HoleDetailPage(hole: PreviewDecode.decodeObj(name: "hole")!)
    }
}

