import SwiftUI
import UIKit
import ViewUtils
import WrappingHStack

struct THHolePage: View {
    @ObservedObject private var settings = THSettings.shared
    @StateObject private var model: THHoleModel
    @State private var showScreenshotAlert = false
    
    private let screenshotPublisher = NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
    
    init(_ hole: THHole) {
        self._model = StateObject(wrappedValue: THHoleModel(hole: hole, floors: hole.floors, loadMore: true))
    }
    
    init(_ model: THHoleModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                THBackgroundList(selection: $model.selectedFloor) {
                    AsyncCollection(model.filteredFloors, endReached: model.endReached, action: model.loadMoreFloors) { floor in
                        Section {
                            THComplexFloor(floor)
                                .tag(floor)
                        } header: {
                            if floor.id == model.floors.first?.id {
                                VStack(alignment: .leading) {
                                    if model.hole.locked {
                                        HStack {
                                            Label("Post locked, reply is forbidden", systemImage: "lock.fill")
                                                .font(.callout)
                                                .foregroundColor(.secondary)
                                                .listRowSeparator(.hidden)
                                            Spacer()
                                        }
                                    }
                                    THHoleTags(tags: model.hole.tags)
                                        .padding(.bottom, 5)
                                        .textCase(.none)
                                }
                            }
                        }
                    }
                }
                // put the onAppear modifier outside, to prevent initial scroll to be performed multiple times
                .onAppear {
                    if let initialScroll = model.initialScroll {
                        model.scrollControl.send(initialScroll)
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
                        THHoleToolbar()
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        THHoleBottomBar()
                    }
                }
                .task {
                    do {
                        try await THRequests.updateViews(holeId: model.hole.id)
                        THModel.shared.appendHistory(hole: model.hole)
                    } catch {}
                }
                .onReceive(screenshotPublisher) { _ in
                    if settings.screenshotAlert {
                        showScreenshotAlert = true
                    }
                }
                .alert("Screenshot Detected", isPresented: $showScreenshotAlert) {} message: {
                    Text("Screenshot Alert Content")
                }
                .environmentObject(model)
            }
            
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
                .transition(.opacity)
                // move the scroll control in view body to prevent calling scroll before new floor is inserted in view
                .onDisappear {
                    if let lastFloorId = model.filteredFloors.last?.id {
                        model.scrollControl.send(lastFloorId)
                    }
                }
            }
        }
    }
}

private struct THHoleToolbar: View {
    @ObservedObject private var appModel = DXModel.shared
    @EnvironmentObject private var model: THHoleModel
    @Environment(\.editMode) private var editMode
    
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showReplySheet = false
    @State private var showQuestionSheet = false
    
    var body: some View {
        Group {
            replyButton
            menu
        }
    }
    
    private var replyButton: some View {
        Button {
            if appModel.answered {
                showReplySheet = true
            } else {
                showQuestionSheet = true
            }
        } label: {
            Image(systemName: "arrowshape.turn.up.left")
        }
        .disabled(model.hole.locked && !appModel.isAdmin)
        .sheet(isPresented: $showReplySheet) {
            THReplySheet()
        }
        .sheet(isPresented: $showQuestionSheet) {
            DXQuestionSheet()
        }
    }
    
    private var menu: some View {
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
                    .tag(THHoleModel.FilterOptions.all)
                
                Label("Show OP Only", systemImage: "person.fill")
                    .tag(THHoleModel.FilterOptions.posterOnly)
            }
            
            AsyncButton {
                await model.loadAllFloors()
                haptic()
            } label: {
                Label("Navigate to Bottom", systemImage: "arrow.down.to.line")
            }
            
            if appModel.isAdmin {
                Divider()
                
                Menu {
                    Button {
                        withAnimation {
                            editMode?.wrappedValue = .active
                        }
                    } label: {
                        Label("Batch Delete", systemImage: "trash")
                    }
                    
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
                } label: {
                    Label("Admin Actions", systemImage: "person.badge.key")
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
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will affect all replies of this post")
        }
    }
}

struct THHoleTags: View {
    @EnvironmentObject private var navigator: THNavigator
    let tags: [THTag]
    
    var body: some View {
        WrappingHStack(alignment: .leading) {
            ForEach(tags) { tag in
                Button {
                    navigator.path.append(tag)
                } label: {
                    THTagView(tag)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

private struct THHoleBottomBar: View {
    @EnvironmentObject private var model: THHoleModel
    @Environment(\.editMode) private var editMode
    @State private var showAlert = false
    @State private var deleteReason = ""
    
    var body: some View {
        Group {
            if model.showBottomBar {
                Button {
                    model.filterOption = .all
                } label: {
                    BottomBarLabel("Show All Floors", systemImage: "bubble.left.and.bubble.right")
                }
            }
            
            if editMode?.wrappedValue.isEditing == true {
                if model.selectedFloor.isEmpty {
                    Button {
                        withAnimation {
                            editMode?.wrappedValue = .inactive
                        }
                    } label: {
                        Text("Cancel")
                    }
                } else {
                    Button(role: .destructive) {
                        showAlert = true
                    } label: {
                        BottomBarLabel("Delete Selected", systemImage: "trash")
                    }
                }
            }
        }
        .alert("Delete Selected", isPresented: $showAlert) {
            TextField("Enter Delete Reason", text: $deleteReason)
            Button(role: .destructive) {
                let floors = Array(model.selectedFloor)
                Task {
                    await model.batchDelete(floors, reason: deleteReason)
                }
                
                withAnimation {
                    editMode?.wrappedValue = .inactive
                }
            } label: {
                Text("Submit")
            }
        }
    }
}

private struct BottomBarLabel: View {
    let text: LocalizedStringKey
    let systemImage: String
    
    init(_ text: LocalizedStringKey, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }
    
    var body: some View {
        // This is for compatibility issue
        // Label will only display icon in bottom bar on iOS 17
        if #available(iOS 17.0, *) {
            HStack {
                Image(systemName: systemImage)
                Text(text)
            }
        } else {
            Label(text, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
        }
    }
}
