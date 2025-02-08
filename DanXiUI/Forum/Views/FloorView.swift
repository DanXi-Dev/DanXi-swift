import DanXiKit
import SwiftUI
import SwiftUIX
import ViewUtils

struct FloorView: View {
    @EnvironmentObject private var holeModel: HoleModel
    @StateObject private var model: FloorModel
    
    init(presentation: FloorPresentation) {
        let model = FloorModel(presentation: presentation)
        self._model = StateObject(wrappedValue: model)
        self.presentation = presentation
    }
    
    private let presentation: FloorPresentation
    
    private var floor: Floor {
        presentation.floor
    }
    
    private var isPoster: Bool {
        floor.anonyname == holeModel.floors.first?.floor.anonyname
    }
    
    var body: some View {
        FoldedView(expand: !floor.collapse) {
            VStack { // These stacks expand the text to fill list row so that hightlight function correctly highlights the entire row, not just the text frame.
                Spacer(minLength: 0)
                HStack {
                    Text(model.foldContent)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
        } content: {
            VStack(alignment: .leading) {
                headLine
                content
                bottomLine
            }
        }
        .listRowInsets(.zero)
        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        .overlay(Color.gray.opacity(model.highlighted ? 0.4 : 0).listRowInsets(.zero).allowsHitTesting(false))
        .onReceive(holeModel.scrollControl) { id in
            if id == presentation.id {
                model.highlight()
            }
        }
        .background {
            RoundedRectangle(cornerSize: .init(width: 10, height: 10), style: .continuous)
                .foregroundStyle(Color("List Foreground", bundle: .module))
        }
        .environmentObject(model)
    }
    
    private var headLine: some View {
        HStack {
            PosterView(name: floor.anonyname, isPoster: isPoster)
                .fixedSize()
            if !floor.specialTag.isEmpty {
                SpecialTagView(content: floor.specialTag)
                    .fixedSize()
            }
            Spacer()
            FloorActions()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if !floor.deleted {
            FloorContentView(sections: presentation.sections, content: floor.content)
                .environment(\.originalFloor, presentation)
        } else {
            Text(floor.content)
                .foregroundColor(.secondary)
        }
    }
    
    private var bottomLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: "\(String(presentation.storey))F")
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text(verbatim: "(##\(String(floor.id)))")
            
            Spacer()
            
            if floor.deleted {
                Text("Deleted", bundle: .module)
            } else if floor.modified {
                Text("Edited", bundle: .module)
            }
            
            Spacer()
            
            Text(floor.timeCreated.autoFormatted())
        }
        .font(.footnote)
        .foregroundColor(Color.secondary.opacity(0.7))
        .padding(.top, 0.8)
    }
}

struct FloorEnvironmentKey: EnvironmentKey {
    static let defaultValue: FloorPresentation? = nil
}

extension EnvironmentValues {
    var originalFloor: FloorPresentation? {
        get { self[FloorEnvironmentKey.self] } set { self[FloorEnvironmentKey.self] = newValue }
    }
}

private struct FloorContentView: View, Equatable {
    @EnvironmentObject private var model: HoleModel
    
    static func == (lhs: FloorContentView, rhs: FloorContentView) -> Bool {
        lhs.content == rhs.content // FIXME: This is supposed to prevent UI flicker during reload, but it didn't work for some examples. It still need further investigation.
    }
    
    let sections: [FloorSection]
    let content: String
    
    private var displaySections: [FloorSection] {
        let sliced = if sections.count > 1 {
            Array(sections[1...])
        } else {
            sections
        }
        
        return switch model.filterOption {
        case .conversation:
            sliced
        case .reply:
            sliced
        default:
            sections
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(displaySections.enumerated()), id: \.offset) { _, section in
                switch section {
                case .text(let markdown):
                    CustomMarkdown(markdown)
                        .environment(\.supportImageBrowsing, true)
                case .localMention(let floor):
                    LocalMentionView(floor)
                case .remoteMention(let mention):
                    RemoteMentionView(mention)
                }
            }
        }
    }
}

private struct FloorActions: View {
    @EnvironmentObject private var holeModel: HoleModel
    @EnvironmentObject private var floorModel: FloorModel
    @ObservedObject private var profileStore = ProfileStore.shared
    
    private var floor: Floor {
        floorModel.floor
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if !floor.deleted {
                likeButton
                Spacer()
                replyButton
            }
            Spacer()
            menu
        }
        .frame(maxWidth: 140)
    }
    
    private var likeButton: some View {
        Group {
            AsyncButton {
                try await withHaptics {
                    try await floorModel.like()
                }
            } label: {
                HStack(alignment: .center, spacing: 3) {
                    Image(systemName: "hand.thumbsup")
                        .symbolVariant(floorModel.liked ? .fill : .none)
                    if floorModel.likeCount > 0 {
                        Text(String(floorModel.likeCount))
                    }
                }
                .foregroundColor(floorModel.liked ? .pink : .secondary)
                .fixedSize() // prevent numbers to disappear when special tag present
            }
            
            Spacer()
            
            AsyncButton {
                try await withHaptics {
                    try await floorModel.dislike()
                }
            } label: {
                HStack(alignment: .center, spacing: 3) {
                    Image(systemName: "hand.thumbsdown")
                        .symbolVariant(floorModel.disliked ? .fill : .none)
                    if floorModel.dislikeCount > 0 {
                        Text(String(floorModel.dislikeCount))
                    }
                }
                .foregroundColor(floorModel.disliked ? .green : .secondary)
                .fixedSize() // prevent numbers to disappear when special tag present
            }
        }
        .buttonStyle(.borderless)
        .font(.caption)
    }
    
    private var replyButton: some View {
        Button {
            holeModel.replySheet = floor
        } label: {
            Image(systemName: "arrowshape.turn.up.left")
        }
        .buttonStyle(.borderless)
        .foregroundColor(.secondary)
        .font(.caption)
    }
    
    private var menu: some View {
        Menu {
            Button {
                holeModel.textSelectionSheet = floor
            } label: {
                Label(String(localized: "Copy Text", bundle: .module), systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button {
                withAnimation {
                    holeModel.filterOption = .user(floor.anonyname)
                }
            } label: {
                Label(String(localized: "Show This Person", bundle: .module), systemImage: "message")
            }
            
            Button {
                withAnimation {
                    holeModel.filterOption = .reply(floor.id)
                }
            } label: {
                Label(String(localized: "All Replies", bundle: .module), systemImage: "arrowshape.turn.up.left.2")
            }
            
            Button {
                withAnimation {
                    holeModel.filterOption = .conversation(floor.id)
                }
            } label: {
                Label(String(localized: "View Conversation", bundle: .module), systemImage: "bubble.left.and.bubble.right")
            }
            .disabled(floorModel.presentation.replyTo == nil)
            
            Divider()
            
            if floor.isMe {
                Button {
                    holeModel.editSheet = floor
                } label: {
                    Label(String(localized: "Edit Reply", bundle: .module), systemImage: "square.and.pencil")
                }
                
                Button(role: .destructive) {
                    holeModel.deleteAlertItem = floor
                } label: {
                    Label(String(localized: "Delete", bundle: .module), systemImage: "trash")
                }
            } else {
                Button(role: .destructive) {
                    holeModel.reportSheet = floorModel.presentation
                } label: {
                    Label(String(localized: "Report", bundle: .module), systemImage: "exclamationmark.triangle")
                }
            }
            
            if profileStore.isAdmin {
                Divider()
                
                Menu {
                    Button {
                        holeModel.editSheet = floor
                    } label: {
                        Label(String(localized: "Modify Floor", bundle: .module), systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        holeModel.deleteSheet = floorModel.presentation
                    } label: {
                        Label(String(localized: "Remove Floor", bundle: .module), systemImage: "xmark.square")
                    }
                    
                    Button {
                        holeModel.historySheet = floor
                    } label: {
                        Label(String(localized: "Show Administrative Info", bundle: .module), systemImage: "info.circle")
                    }
                } label: {
                    Label(String(localized: "Admin Actions", bundle: .module), systemImage: "person.badge.key")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .imageScale(.large)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct MultipleFoldedFloorView: View {
    @EnvironmentObject private var holeModel: HoleModel
    @State var highlighted = false
    let presentations: [FloorPresentation]
    private let id = UUID()
    
    // FIXME: duplicate code
    func highlight() {
        Task { @MainActor in
            withAnimation {
                highlighted = true
            }
            try await Task.sleep(for: .seconds(0.1))
            withAnimation {
                highlighted = false
            }
            try await Task.sleep(for: .seconds(0.2))
            withAnimation {
                highlighted = true
            }
            try await Task.sleep(for: .seconds(0.1))
            withAnimation {
                highlighted = false
            }
        }
    }
    
    var body: some View {
        Section {
            VStack {
                // These stacks expand the text to fill list row so that hightlight function correctly highlights the entire row, not just the text frame.
                Spacer(minLength: 0)
                HStack {
                    Text("\(presentations.count) hidden items", bundle: .module)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
            .foregroundColor(.secondary)
            .font(.subheadline)
            .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .overlay(Color.gray.opacity(highlighted ? 0.2 : 0).listRowInsets(.zero).allowsHitTesting(false))
        }
        .background {
            RoundedRectangle(cornerSize: .init(width: 10, height: 10), style: .continuous)
                .foregroundStyle(Color("List Foreground", bundle: .module))
        }
        
        // FIXME: This ID modifier don't seems to have effect when scrolling
        .id(id)
        .onReceive(holeModel.scrollControl) { id in
            if presentations.contains(where: { $0.id == id }) {
                highlight()
                // FIXME: holeModel.scrollControl.send(self.id)
            }
        }
    }
}

#Preview {
    let hole: Hole = decodePreviewData(filename: "hole", directory: "forum")
    let holeModel = HoleModel(hole: hole)
    let floor: Floor = decodePreviewData(filename: "floor", directory: "forum")
    let presentation = FloorPresentation(floor: floor, storey: 1)
    
    List {
        FloorView(presentation: presentation)
            .environmentObject(holeModel)
    }
}
