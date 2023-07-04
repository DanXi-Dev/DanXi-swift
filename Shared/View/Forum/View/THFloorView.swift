import SwiftUI
import SwiftUIX

struct THSimpleFloor: View {
    let floor: THFloor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            THPosterView(name: floor.posterName, isPoster: false)
            MarkdownView(floor.content)
                .foregroundColor(floor.deleted ? .secondary : .primary)
            bottom
        }
    }

    var bottom: some View {
        HStack {
            Text("##\(String(floor.id))")
            Spacer()
            Text(floor.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
        }
        .font(.caption)
        .foregroundColor(.separator)
    }
}


struct THComplexFloor: View {
    @EnvironmentObject private var holeModel: THHoleModel
    @StateObject private var model: THFloorModel
    
    init(_ floor: THFloor, highlighted: Bool = false) {
        let model = THFloorModel(floor: floor, highlighted: highlighted)
        self._model = StateObject(wrappedValue: model)
    }
    
    private var floor: THFloor {
        model.floor
    }
    
    private var text: String {
        switch holeModel.filterOption {
        case .conversation(_):
            return floor.removeFirstMention()
        case .reply(_):
            return floor.removeFirstMention()
        default:
            return floor.content
        }
    }
    
    var body: some View {
        FoldedView(expand: !model.collapse) {
            Text(model.collapsedContent)
                .foregroundColor(.secondary)
        } content: {
            VStack(alignment: .leading) {
                headLine
                content
                bottomLine
            }
        }
        .environmentObject(model)
        // highlight control
        .listRowBackground(Color.separator.opacity(model.highlighted ? 0.5 : 0))
        .onChange(of: holeModel.scrollTarget) { target in
            if target != model.floor.id { return }
            model.highlight()
        }
        .onAppear {
            if model.highlighted {
                model.highlight()
            }
        }
        // update floor when batch delete
        .onReceive(holeModel.deleteBroadcast) { ids in
            if ids.contains(floor.id) {
                if let newFloor = holeModel.floors.filter({ $0.id == floor.id }).first {
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
            THPosterView(name: floor.posterName,
                         isPoster: isPoster)
            if !model.floor.spetialTag.isEmpty {
                THSpecialTagView(content: floor.spetialTag)
            }
            Spacer()
            Actions()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if !floor.deleted {
            THFloorContent(text)
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
            
            Text(floor.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
        }
        .font(.caption)
        .foregroundColor(Color.secondary.opacity(0.7))
        .padding(.top, 2.0)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct THFloorContent: View {
    @OptionalEnvironmentObject var holeModel: THHoleModel?
    @OptionalEnvironmentObject var floorModel: THFloorModel?
    
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
        
        var partialContent = self.content
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
                    MarkdownView(content)
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

// MARK: - Components

fileprivate struct Actions: View {
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
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            if !model.floor.deleted {
                likeButton
                replyButton
            }
            menu
        }
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
            showReplySheet = true
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
            Button {
                showReportSheet = true
            } label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            }
            
            Button {
                showSelectionSheet = true
            } label: {
                Label("Select Text", systemImage: "selection.pin.in.out")
            }
            
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
            
            if model.floor.firstMention() != nil {
                Button {
                    holeModel.filterOption = .conversation(starting: model.floor.id)
                } label: {
                    Label("View Conversation", systemImage: "bubble.left.and.bubble.right")
                }
            }
            
            if model.floor.isMe {
                Divider()
                
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
            }
            
            if appModel.isAdmin {
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

fileprivate struct TextSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
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
