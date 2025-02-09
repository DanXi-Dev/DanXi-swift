import DanXiKit
import SwiftUI
import ViewUtils

struct HolePage: View {
    @StateObject private var model: HoleModel
    @ObservedObject private var profileStore = ProfileStore.shared
    
    private var hole: Hole {
        model.hole
    }
    
    init(_ hole: Hole) {
        let model = HoleModel(hole: hole)
        self._model = StateObject(wrappedValue: model)
    }
    
    init(_ model: HoleModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            HolePageSheets {
                // Use ScrollView and LazyVStack instead of ForumList to fix overflow problem,
                // see https://github.com/DanXi-Dev/DanXi-swift/pull/313.
                ScrollView {
                    LazyVStack {
                        // On older platform, adjusting list section spacing will hide section header
                        // due to implementation of compactSectionSpacing.
                        Group {
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
                                    .id(presentation.id)
                                    .onDisappear {
                                        if presentation.id == model.targetFloorId {
                                            model.targetFloorVisibility = false
                                        }
                                    }
                                case .folded(let presentations):
                                    FoldedView {
                                        MultipleFoldedFloorView(presentations: presentations)
                                    } content: {
                                        ForEach(presentations) { presentation in
                                            Section {
                                                FloorView(presentation: presentation)
                                            }
                                            .id(presentation.id)
                                        }
                                    }
                                    .listRowInsets(.zero)
                                    .onDisappear {
                                        for presentation in presentations {
                                            if presentation.id == model.targetFloorId {
                                                model.targetFloorVisibility = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        // To get rid of the animation bug in LazyVStack,
                        // same as .geometryGroup() but available in iOS 16.
                        // See https://stackoverflow.com/questions/78209143/weird-animation-bug-inside-scrollview-with-lazyhstack.
                        .transformEffect(.identity)
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
                    // reset initial scroll to prevent the post from scrolling again.
                    // the post would appear again, when, for example, user exit from image browser.
                    model.initialScroll = nil
                }
            }
            .onReceive(model.scrollControl) { id in
                withAnimation {
                    proxy.scrollTo(id, anchor: .top)
                }
            }
            .navigationTitle(String("#\(String(model.hole.id))"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbar
                }
                
                ToolbarItem(placement: .bottomBar) {
                    bottomBar
                }
            }
            .overlay(alignment: .bottom) {
                if let originalFloor = model.scrollFrom {
                    ReturnCapsule(originalFloor: originalFloor)
                        .id(originalFloor.id)
                        .padding(.bottom, 20)
                }
            }
            .environmentObject(model)
            .task {
                HistoryStore.shared.saveHistory(hole: hole)
                try? await ForumAPI.updateHoleViews(id: hole.id)
            }
            .userActivity("com.fduhole.forum.viewing-hole", element: model.hole.id) { holeId, userActivity in
                userActivity.title = String(localized: "Viewing #\(String(holeId))", bundle: .module)
                userActivity.isEligibleForHandoff = true
                userActivity.userInfo = ["hole-id": holeId]
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading) {
            if hole.locked {
                HStack {
                    Label(String(localized: "Post locked, reply is forbidden", bundle: .module), systemImage: "lock.fill")
                        .textCase(.none)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                    Spacer()
                }
            }
            
            if hole.hidden && profileStore.isAdmin {
                HStack {
                    Label {
                        Text("This hole has been hidden", bundle: .module)
                    } icon: {
                        Image(systemName: "eye.slash.fill")
                    }
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
                try await withHaptics {
                    try await model.toggleFavorite()
                }
            } label: {
                if model.isFavorite {
                    Label(String(localized: "Unfavorite", bundle: .module), systemImage: "star.slash")
                } else {
                    Label(String(localized: "Favorite", bundle: .module), systemImage: "star")
                }
            }
            
            AsyncButton {
                try await withHaptics {
                    try await model.toggleSubscribe()
                }
            } label: {
                if model.subscribed {
                    Label(String(localized: "Unsubscribe", bundle: .module), systemImage: "bell.slash")
                } else {
                    Label(String(localized: "Subscribe", bundle: .module), systemImage: "bell")
                }
            }
            
            Picker(selection: $model.filterOption) {
                Label(String(localized: "Show All", bundle: .module), systemImage: "list.bullet")
                    .tag(HoleModel.FilterOptions.all)
                
                Label(String(localized: "Show OP Only", bundle: .module), systemImage: "person.fill")
                    .tag(HoleModel.FilterOptions.posterOnly)
            } label: {
                Text("Filter Options", bundle: .module)
            }
            
            AsyncButton {
                try await withHaptics {
                    if !model.endReached {
                        try await model.loadAllFloors()
                    }
                    model.scrollToBottom()
                }
            } label: {
                Label(String(localized: "Navigate to Bottom", bundle: .module), systemImage: "arrow.down.to.line")
            }
            
            Divider()
            
            Button {
                model.showCopySheet = true
            } label: {
                Label {
                    Text("Copy Text", bundle: .module)
                } icon: {
                    Image(systemName: "document.on.document")
                }
            }
            
            if profileStore.isAdmin {
                Divider()
                
                Menu {
                    if !model.hole.hidden {
                        Button {
                            model.showHideAlert = true
                        } label: {
                            Label(String(localized: "Hide Hole", bundle: .module), systemImage: "eye.slash.fill")
                        }
                    }
                    
                    Button {
                        model.showHoleEditSheet = true
                    } label: {
                        Label(String(localized: "Edit Post Info", bundle: .module), systemImage: "info.circle")
                    }
                } label: {
                    Label(String(localized: "Admin Actions", bundle: .module), systemImage: "person.badge.key")
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
                        Text("Show All Floors", bundle: .module)
                    }
                } else {
                    Label(String(localized: "Show All Floors", bundle: .module), systemImage: "bubble.left.and.bubble.right")
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
                ReplySheet(content: "##\(String(floor.id))\n")
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
                FloorHistorySheet(floor: floor)
            }
            .sheet(item: $model.textSelectionSheet) { floor in
                TextSelectionSheet(text: floor.content)
            }
            .sheet(isPresented: $model.showCopySheet) {
                HoleCopySheet()
                    .environmentObject(model)
            }
            .alert(String(localized: "Confirm Delete Post", bundle: .module), isPresented: $model.showHideAlert) {
                Button(role: .destructive) {
                    Task {
                        try await ForumAPI.deleteHole(id: model.hole.id)
                        model.hole = try await ForumAPI.getHole(id: model.hole.id)
                    }
                } label: {
                    Text("Confirm", bundle: .module)
                }
                
                Button(role: .cancel) {
                    
                } label: {
                    Text("Cancel", bundle: .module)
                }
            } message: {
                Text("This will affect all replies of this post", bundle: .module)
            }
            .alert(String(localized: "Delete Floor", bundle: .module), isPresented: $model.showDeleteAlert) {
                Button(role: .destructive) {
                    guard let floor = model.deleteAlertItem else { return }
                    model.deleteAlertItem = nil
                    Task {
                        try await model.deleteFloor(floorId: floor.id)
                    }
                } label: {
                    Text("Delete", bundle: .module)
                }
            } message: {
                Text("This floor will be deleted", bundle: .module)
            }
            .overlay {
                if model.loadingAll {
                    HStack(spacing: 20) {
                        ProgressView()
                        Text("Loading", bundle: .module)
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

#Preview {
    let hole: Hole = decodePreviewData(filename: "hole", directory: "forum")
    let floors: [Floor] = decodePreviewData(filename: "floors", directory: "forum")
    let model = HoleModel(hole: hole, floors: floors)
    
    NavigationStack {
        HolePage(model)
    }
    .onAppear {
        model.endReached = true
    }
}
