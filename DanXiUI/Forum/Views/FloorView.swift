import SwiftUI
import SwiftUIX
import DanXiKit
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
    
    private var fold: Bool {
        floor.deleted || !floor.fold.isEmpty
    }
    
    private var isPoster: Bool {
        floor.anonyname == holeModel.floors.first?.floor.anonyname
    }
    
    var body: some View {
        FoldedView(expand: !model.shouldFold) {
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
        .overlay(Color.accentColor.opacity(model.highlighted ? 0.5 : 0).listRowInsets(.zero).allowsHitTesting(false))
        .onReceive(holeModel.scrollControl) { id in
            if id == presentation.id {
                model.highlight()
            }
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
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(presentation.sections.enumerated()), id: \.offset) { _, section in
                    switch section {
                    case .text(let markdown):
                        CustomMarkdown(markdown)
                    case .localMention(let floor):
                        LocalMentionView(floor)
                    case .remoteMention(let mention):
                        RemoteMentionView(mention)
                    }
                }
            }
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
                Text("Deleted")
            } else if floor.modified {
                Text("Edited")
            }
            
            Spacer()
            
            Text(floor.timeCreated.autoFormatted())
        }
        .font(.footnote)
        .foregroundColor(Color.secondary.opacity(0.7))
        .padding(.top, 0.8)
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
                UIPasteboard.general.string = NSAttributedString(floor.content.inlineAttributed()).string
            } label: {
                Label("Copy Full Text", systemImage: "doc.on.doc")
            }
            
            Button {
                holeModel.textSelectionSheet = floor
            } label: {
                Label("Select Text", systemImage: "character.cursor.ibeam")
            }
            
            Button {
                withAnimation {
                    holeModel.filterOption = .user(floor.anonyname)
                }
            } label: {
                Label("Show This Person", systemImage: "message")
            }
            
            Button {
                withAnimation {
                    holeModel.filterOption = .reply(floor.id)
                }
            } label: {
                Label("All Replies", systemImage: "arrowshape.turn.up.left.2")
            }
            
            Button {
                withAnimation {
                    holeModel.filterOption = .conversation(floor.id)
                }
            } label: {
                Label("View Conversation", systemImage: "bubble.left.and.bubble.right")
            }
            .disabled(floorModel.presentation.replyTo == nil)
            
            Divider()
            
            if floor.isMe {
                Button {
                    holeModel.editSheet = floor
                } label: {
                    Label("Edit Reply", systemImage: "square.and.pencil")
                }
                
                Button(role: .destructive) {
                    holeModel.deleteAlertItem = floor
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button(role: .destructive) {
                    holeModel.reportSheet = floorModel.presentation
                } label: {
                    Label("Report", systemImage: "exclamationmark.triangle")
                }
            }
            
            if profileStore.isAdmin {
                Divider()
                
                Menu {
                    Button {
                        holeModel.editSheet = floor
                    } label: {
                        Label("Modify Floor", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        holeModel.deleteSheet = floorModel.presentation
                    } label: {
                        Label("Remove Floor", systemImage: "xmark.square")
                    }
                    
                    Button {
                        holeModel.historySheet = floor
                    } label: {
                        Label("Show Administrative Info", systemImage: "info.circle")
                    }
                } label: {
                    Label("Admin Actions", systemImage: "person.badge.key")
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
