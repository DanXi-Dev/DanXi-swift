import SwiftUI
import DanXiKit
import ViewUtils

struct HolePage: View {
    @StateObject private var model: HoleModel
    @ObservedObject private var profileStore = ProfileStore.shared
    
    private var hole: Hole {
        model.hole
    }
    
    init(_ hole: Hole) {
        let model = HoleModel(hole: hole, floors: hole.prefetch, refreshPrefetch: true)
        self._model = StateObject(wrappedValue: model)
    }
    
    init(_ model: HoleModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            HolePageSheets {
                ForumList {
                    // On older platform, adjusting list section spacing will hide section header
                    // due to implementation of compactSectionSpacing.
                    if #unavailable(iOS 17) {
                        header
                            .listRowBackground(Color.clear)
                    }
                    
                    AsyncCollection(model.filteredSegments, endReached: model.endReached, action: model.loadMoreFloors) { segment in
                        switch segment {
                        case .floor(let presentation):
                            Section {
                                FloorView(presentation: presentation)
                            } header: {
                                if presentation.id == model.floors.first?.id {
                                    header
                                }
                            }
                        case .folded(let presentations):
                            if presentations.count == 1, let first = presentations.first {
                                Section {
                                    FloorView(presentation: first)
                                } header: {
                                    if first.id == model.floors.first?.id {
                                        header
                                    }
                                }
                            } else {
                                FoldedView {
                                    Section {
                                        MultipleFoldedFloorView(presentations: presentations)
                                    }
                                } content: {
                                    ForEach(presentations) { presentation in
                                        Section {
                                            FloorView(presentation: presentation)
                                        }
                                    }
                                }
                                .listRowInsets(.zero)
                            }
                        }
                    }
                }
                .refreshable {
                    try? await withHaptics(success: false) {
                        try await model.refreshAllFloors()
                    }
                }
            }
            .environment(\.allImageURL, model.imageURLs)
            .watermark()
            .screenshotAlert()
            // put the onAppear modifier outside, to prevent initial scroll to be performed multiple times
            .onAppear {
                if let initialScroll = model.initialScroll {
                    model.scrollTo(floorId: initialScroll)
                }
            }
            .onReceive(model.scrollControl) { id in
                withAnimation {
                    proxy.scrollTo(id, anchor: .top)
                }
            }
            .navigationTitle("#\(String(model.hole.id))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbar
                }
                
                ToolbarItem(placement: .bottomBar) {
                    bottomBar
                }
            }
            .environmentObject(model)
            .task {
                HistoryStore.shared.saveHistory(hole: hole)
                try? await ForumAPI.updateHoleViews(id: hole.id)
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading) {
            if hole.locked {
                HStack {
                    Label("Post locked, reply is forbidden", systemImage: "lock.fill")
                        .textCase(.none)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                    Spacer()
                }
            }
            
            tags
        }
    }
    
    private var tags: some View {
        WrappingHStack(alignment: .leading) {
            ForEach(hole.tags) { tag in
                ContentLink(value: tag) {
                    TagView(tag.name)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.bottom, 5)
    }
    
    @ViewBuilder
    private var toolbar: some View {
        Button {
            if profileStore.answered {
                model.showReplySheet = true
            } else {
                model.showQuestionSheet = true
            }
        } label: {
            Image(systemName: "arrowshape.turn.up.left")
        }
        .disabled(hole.locked && !profileStore.isAdmin)
        
        Menu {
            AsyncButton {
                try await model.toggleFavorite()
            } label: {
                if model.isFavorite {
                    Label("Unfavorite", systemImage: "star.slash")
                } else {
                    Label("Favorite", systemImage: "star")
                }
            }
            
            AsyncButton {
                try await model.toggleSubscribe()
            } label: {
                if model.subscribed {
                    Label("Unsubscribe", systemImage: "bell.slash")
                } else {
                    Label("Subscribe", systemImage: "bell")
                }
            }
            
            Picker("Filter Options", selection: $model.filterOption) {
                Label("Show All", systemImage: "list.bullet")
                    .tag(HoleModel.FilterOptions.all)
                
                Label("Show OP Only", systemImage: "person.fill")
                    .tag(HoleModel.FilterOptions.posterOnly)
            }
            
            AsyncButton {
                try await withHaptics {
                    if !model.endReached {
                        try await model.loadAllFloors()
                    }
                    model.scrollToBottom()
                }
            } label: {
                Label("Navigate to Bottom", systemImage: "arrow.down.to.line")
            }
            
            if profileStore.isAdmin {
                Divider()
                
                Menu {
                    if !model.hole.hidden {
                        Button {
                            model.showHideAlert = true
                        } label: {
                            Label("Hide Hole", systemImage: "eye.slash.fill")
                        }
                    }
                    
                    Button {
                        model.showHoleEditSheet = true
                    } label: {
                        Label("Edit Post Info", systemImage: "info.circle")
                    }
                } label: {
                    Label("Admin Actions", systemImage: "person.badge.key")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    @ViewBuilder
    private var bottomBar: some View {
        if model.filterOption != .all && model.filterOption != .posterOnly {
            Button {
                withAnimation {
                    model.filterOption = .all
                }
            } label: {
                // This is for compatibility issue
                // Label will only display icon in bottom bar on iOS 17
                if #available(iOS 17.0, *) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("Show All Floors")
                    }
                } else {
                    Label("Show All Floors", systemImage: "bubble.left.and.bubble.right")
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }
}

private struct HolePageSheets<Label: View>: View {
    @EnvironmentObject private var model: HoleModel
    let label: () -> Label
    
    var body: some View {
        label()
            .sheet(isPresented: $model.showReplySheet) {
                ReplySheet()
            }
            .sheet(isPresented: $model.showQuestionSheet) {
                QuestionSheet()
            }
            .sheet(isPresented: $model.showHoleEditSheet) {
                HoleEditSheet(hole: model.hole)
            }
            .sheet(item: $model.replySheet) { floor in
                ReplySheet(content: "##\(String(floor.id))")
            }
            .sheet(item: $model.editSheet) { floor in
                FloorEditSheet(floor: floor)
            }
            .sheet(item: $model.reportSheet) { presentation in
                ReportSheet(presentation: presentation)
            }
            .sheet(item: $model.deleteSheet) { presentation in
                DeleteSheet(presentation: presentation)
            }
            .sheet(item: $model.historySheet) { floor in
                FloorHistorySheet(floorId: floor.id)
            }
            .sheet(item: $model.textSelectionSheet) { floor in
                TextSelectionSheet(text: floor.content)
            }
            .alert("Confirm Delete Post", isPresented: $model.showHideAlert) {
                Button("Confirm", role: .destructive) {
                    Task {
                        try await ForumAPI.deleteHole(id: model.hole.id)
                        model.hole = try await ForumAPI.getHole(id: model.hole.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will affect all replies of this post")
            }
            .alert("Delete Floor", isPresented: $model.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        if let floor = model.deleteAlertItem {
                            try await model.deleteFloor(floorId: floor.id)
                        }
                    }
                }
            } message: {
                Text("This floor will be deleted")
            }
            .overlay {
                if model.loadingAll {
                    HStack(spacing: 20) {
                        ProgressView()
                        Text("Loading")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 45)
                    .padding(.vertical, 25)
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )
                    .animation(.default, value: model.loadingAll)
                    .transition(.opacity)
                }
            }
    }
}
