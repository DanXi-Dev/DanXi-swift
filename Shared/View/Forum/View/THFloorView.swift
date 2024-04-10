import SwiftUI
import SwiftUIX
import ViewUtils

struct THSimpleFloor: View {
    let floor: THFloor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            THPosterView(name: floor.posterName, isPoster: false)
            Text(floor.content.inlineAttributed())
                .font(.callout)
                .foregroundColor(floor.deleted ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
            bottom
        }
        .listRowInsets(EdgeInsets(top: 11, leading: 11, bottom: 11, trailing: 11))
    }
    
    var bottom: some View {
        HStack {
            Text("##\(String(floor.id))")
            Spacer()
            Text(floor.createTime.autoFormatted())
        }
        .font(.caption)
        .foregroundColor(.separator)
    }
}

struct THComplexFloor: View {
    @Environment(\.editMode) private var editMode
    
    @EnvironmentObject private var holeModel: THHoleModel
    @StateObject private var model: THFloorModel
    
    init(_ floor: THFloor) {
        self._model = StateObject(wrappedValue: THFloorModel(floor: floor))
    }
    
    private var floor: THFloor {
        model.floor
    }
    
    private var text: String {
        switch holeModel.filterOption {
        case .conversation:
            return floor.removeFirstMention()
        case .reply:
            return floor.removeFirstMention()
        default:
            return floor.content
        }
    }
    
    var body: some View {
        FoldedView(expand: !model.collapse) {
            Text(model.collapsedContent)
                .foregroundColor(.secondary)
                .font(.subheadline)
        } content: {
            VStack(alignment: .leading) {
                headLine
                content
                bottomLine
            }
        }
        .listRowInsets(.zero)
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        // highlight control
        .overlay(Color.accentColor.opacity(model.highlighted ? 0.5 : 0).listRowInsets(.zero).allowsHitTesting(false))
        .environmentObject(model)
        // prevent interactions (like, scroll to, image popover, ...) in batch delete mode
        .disabled(editMode?.wrappedValue.isEditing ?? false)
        .onReceive(holeModel.scrollControl) { id in
            if id == model.floor.id {
                model.highlight()
            }
        }
        // update floor when batch delete
        .onReceive(holeModel.floorChangedBroadcast) { ids in
            if ids.contains(floor.id) {
                if let newFloor = holeModel.floors.first(where: { $0.id == floor.id }) {
                    model.floor = newFloor
                }
            }
        }
    }
    
    private var full: some View {
        VStack(alignment: .leading) {
            headLine
            content
            bottomLine
        }
    }
    
    private var headLine: some View {
        HStack {
            let isPoster = floor.posterName == holeModel.floors.first?.posterName
            THPosterView(name: floor.posterName, isPoster: isPoster)
                .fixedSize()
            if !model.floor.spetialTag.isEmpty {
                THSpecialTagView(content: floor.spetialTag)
                    .fixedSize()
            }
            Spacer()
            Actions()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if !floor.deleted {
            THFloorContent(text)
                .equatable(by: text)
        } else {
            Text(floor.content)
                .foregroundColor(.secondary)
        }
    }
    
    private var bottomLine: some View {
        HStack {
            Text("\(String(floor.storey))F")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text("(##\(String(floor.id)))")
                .font(.caption2)
            
            Spacer()
            
            if floor.deleted {
                Text("Deleted")
            } else if floor.modified != 0 {
                Text("Edited")
            }
            
            Spacer()
            
            Text(floor.createTime.autoFormatted())
        }
        .font(.caption)
        .foregroundColor(Color.secondary.opacity(0.7))
        .padding(.top, 2.0)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct THFloorContent: View {
    @EnvironmentObject.Optional var holeModel: THHoleModel?
    @EnvironmentObject.Optional var floorModel: THFloorModel?
    
    let content: String
    let interactable: Bool
    
    init(_ content: String, interactable: Bool = true) {
        self.content = content
        self.interactable = interactable
    }
    
    struct ReferenceItem: Identifiable {
        let type: ReferenceType
        let id: Int
    }
    
    enum ReferenceType {
        case text(content: String)
        case local(floor: THFloor)
        case remote(mention: THMention)
    }
    
    func parse() -> [ReferenceItem] {
        let floors = holeModel?.floors ?? []
        let mentions = floorModel?.floor.mention ?? []
        
        var partialContent = content
        var parsedElements: [ReferenceItem] = []
        var count = 0
        
        while let match = partialContent.firstMatch(of: /(?<prefix>#{1,2})(?<id>\d+)/) {
            // first part of text
            let previous = String(partialContent[partialContent.startIndex..<match.range.lowerBound])
            if !previous.isEmpty {
                count += 1
                parsedElements.append(ReferenceItem(type: .text(content: previous), id: count))
            }
            
            // match
            if match.prefix == "##" { // floor match
                let floorId = Int(match.id)
                if let floor = floors.filter({ $0.id == floorId }).first {
                    count += 1
                    parsedElements.append(ReferenceItem(type: .local(floor: floor), id: count))
                } else if let mention = mentions.filter({ $0.floorId == floorId }).first {
                    count += 1
                    parsedElements.append(ReferenceItem(type: .remote(mention: mention), id: count))
                }
            } else {
                let holeId = Int(match.id)
                if let mention = mentions.filter({ $0.holeId == holeId }).first {
                    count += 1
                    parsedElements.append(ReferenceItem(type: .remote(mention: mention), id: count))
                }
            }
            
            // cut
            partialContent = String(partialContent[match.range.upperBound..<partialContent.endIndex])
        }
        
        if !partialContent.isEmpty {
            count += 1
            parsedElements.append(ReferenceItem(type: .text(content: partialContent), id: count))
        }
        
        return parsedElements
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            let items = parse()
            
            ForEach(items) { item in
                switch item.type {
                case .text(let content):
                    CustomMarkdown(content)
                case .local(let floor):
                    if interactable {
                        THLocalMentionView(floor)
                    } else {
                        THMentionView(floor: floor)
                    }
                case .remote(let mention):
                    if interactable {
                        THRemoteMentionView(mention: mention)
                    } else {
                        THMentionView(mention: mention)
                    }
                }
            }
        }
    }
}

struct THFloorParagraph: View {
    let text: Text
    
    init(_ paragraph: AttributedString) {
        var attributedContent = paragraph
        var content = String(paragraph.characters)
        var text = Text("")
        
        while let match = content.firstMatch(of: /\^\[(?<id>[a-zA-Z0-9_]*)\]/) {
            guard let lowerBound = AttributedString.Index(match.range.lowerBound, within: attributedContent),
                  let upperBound = AttributedString.Index(match.range.upperBound, within: attributedContent)
            else {
                text = text + Text(attributedContent)
                break
            }
            // previous text
            let previous = attributedContent[attributedContent.startIndex..<lowerBound]
            text = text + Text(AttributedString(previous))
            
            // image
            if let sticker = THSticker(rawValue: String(match.id)) {
                text = text + Text(sticker.image)
            } else {
                let unmatched = attributedContent[lowerBound..<upperBound]
                text = text + Text(AttributedString(unmatched))
            }
            
            // truncate
            attributedContent = AttributedString(attributedContent[upperBound..<attributedContent.endIndex])
            content = String(content[match.range.upperBound..<content.endIndex])
        }
        
        text = text + Text(attributedContent)
        self.text = text
    }
    
    var body: some View {
        text
            .font(.callout)
            .fixedSize(horizontal: false, vertical: true)
    }
}

enum THSticker: String, CaseIterable {
    case angry = "dx_angry"
    case call = "dx_call"
    case cate = "dx_cate"
    case egg = "dx_egg"
    case fright = "dx_fright"
    case heart = "dx_heart"
    case hug = "dx_hug"
    case overwhelm = "dx_overwhelm"
    case roll = "dx_roll"
    case roped = "dx_roped"
    case sleep = "dx_sleep"
    case swim = "dx_swim"
    case thrill = "dx_thrill"
    case touchFish = "dx_touch_fish"
    case twin = "dx_twin"
    
    var image: Image {
        switch self {
        case .angry: Image("Angry")
        case .call: Image("Call")
        case .cate: Image("Cate")
        case .egg: Image("Egg")
        case .fright: Image("Fright")
        case .heart: Image("Heart")
        case .hug: Image("Hug")
        case .overwhelm: Image("Overwhelm")
        case .roll: Image("Roll")
        case .roped: Image("Roped")
        case .sleep: Image("Sleep")
        case .swim: Image("Swim")
        case .thrill: Image("Thrill")
        case .touchFish: Image("Touch Fish")
        case .twin: Image("Twin")
        }
    }
}

// MARK: - Components

private struct Actions: View {
    @ObservedObject private var appModel = DXModel.shared
    @EnvironmentObject private var holeModel: THHoleModel
    @EnvironmentObject private var model: THFloorModel
    
    @State private var showReplySheet = false
    @State private var showReportSheet = false
    @State private var showSelectionSheet = false
    @State private var showEditSheet = false
    @State private var showHistorySheet = false
    @State private var showDeleteAlert = false
    @State private var showDeleteSheet = false
    @State private var showRemoveSheet = false
    @State private var showQuestionSheet = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if !model.floor.deleted {
                likeButton
                Spacer()
                replyButton
            }
            Spacer()
            menu
        }
        .frame(maxWidth: 140)
        .sheet(isPresented: $showReportSheet) {
            THReportSheet()
        }
        .sheet(isPresented: $showSelectionSheet) {
            TextSelectionSheet(text: model.floor.content)
        }
        .sheet(isPresented: $showHistorySheet) {
            THHistorySheet()
        }
        .sheet(isPresented: $showRemoveSheet) {
            THDeleteSheet()
        }
        .sheet(isPresented: $showEditSheet) {
            THFloorEditSheet(model.floor.content)
        }
        .sheet(isPresented: $showQuestionSheet) {
            DXQuestionSheet()
        }
        .alert("Delete Floor", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await model.delete()
                    }
                }
            }
        } message: {
            Text("This floor will be deleted")
        }
    }
    
    private var likeButton: some View {
        Group {
            let floor = model.floor
            AsyncButton {
                try await model.like()
                haptic()
            } label: {
                HStack(alignment: .center, spacing: 3) {
                    Image(systemName: "hand.thumbsup")
                        .symbolVariant(floor.liked ? .fill : .none)
                    if floor.like > 0 {
                        Text(String(floor.like))
                    }
                }
                .foregroundColor(floor.liked ? .pink : .secondary)
                .fixedSize() // prevent numbers to disappear when special tag present
            }
            
            Spacer()
            
            AsyncButton {
                try await model.dislike()
                haptic()
            } label: {
                HStack(alignment: .center, spacing: 3) {
                    Image(systemName: "hand.thumbsdown")
                        .symbolVariant(floor.disliked ? .fill : .none)
                    if floor.dislike > 0 {
                        Text(String(floor.dislike))
                    }
                }
                .foregroundColor(floor.disliked ? .green : .secondary)
                .fixedSize() // prevent numbers to disappear when special tag present
            }
        }
        .buttonStyle(.borderless)
        .font(.caption)
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
        .buttonStyle(.borderless)
        .foregroundColor(.secondary)
        .font(.caption)
        .sheet(isPresented: $showReplySheet) {
            THReplySheet("##\(String(model.floor.id))")
        }
    }
    
    private var menu: some View {
        Menu {
            Button  {
                UIPasteboard.general.string = NSAttributedString(model.floor.content.inlineAttributed()).string
            } label: {
                Label("Copy Full Text", systemImage: "doc.on.doc")
            }
            
            Button {
                UIPasteboard.general.string = "##\(model.floor.id)"
            } label: {
                Label("Copy Floor ID", systemImage: "number")
            }
            
            Button {
                showSelectionSheet = true
            } label: {
                Label("Select Text", systemImage: "character.cursor.ibeam")
            }
            
            Divider()
            
            Button {
                holeModel.filterOption = .user(name: model.floor.posterName)
            } label: {
                Label("Show This Person", systemImage: "message")
            }
            
            Button {
                holeModel.filterOption = .reply(floorId: model.floor.id)
            } label: {
                Label("All Replies", systemImage: "arrowshape.turn.up.left.2")
            }
            
            Button {
                holeModel.filterOption = .conversation(starting: model.floor.id)
            } label: {
                Label("View Conversation", systemImage: "bubble.left.and.bubble.right")
            }
            .disabled(model.floor.firstMention() == nil)
            
            Divider()
            
            if model.floor.isMe {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Reply", systemImage: "square.and.pencil")
                }
                
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button(role: .destructive) {
                    showReportSheet = true
                } label: {
                    Label("Report", systemImage: "exclamationmark.triangle")
                }
            }
            
            if appModel.isAdmin {
                Divider()
                
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Modify Floor", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showRemoveSheet = true
                    } label: {
                        Label("Remove Floor", systemImage: "xmark.square")
                    }
                    
                    Button {
                        showHistorySheet = true
                    } label: {
                        Label("Show Edit History", systemImage: "clock.arrow.circlepath")
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

private struct TextSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let text: String
    
    var body: some View {
        NavigationStack {
            SelectableText(text: text)
                .padding(.horizontal)
                .navigationTitle("Select Text")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .status) {
                        Button {
                            UIPasteboard.general.string = text
                            dismiss()
                        } label: {
                            Label {
                                Text("Copy Full Text")
                                    .bold()
                            } icon: {
                                Image(systemName: "doc.on.doc")
                            }
                            .labelStyle(.titleAndIcon)
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
        }
    }
}

fileprivate struct SelectableText: UIViewRepresentable {
    let text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.text = text
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .preferredFont(forTextStyle: .body)
        return textView
    }
    
    func updateUIView(_ view: UITextView, context: Context) {
        view.text = text
    }
}
