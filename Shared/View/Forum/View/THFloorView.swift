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
    @EnvironmentObject var holeModel: THHoleModel
    @StateObject var model: THFloorModel
    
    init(_ floor: THFloor, context: THHoleModel) {
        let model = THFloorModel(floor: floor, context: context)
        self._model = StateObject(wrappedValue: model)
    }
    
    private var floor: THFloor {
        model.floor
    }
    
    private var text: String {
        switch holeModel.filterOption {
        case .conversation(_):
            return floor.removeFirstMention()
        default:
            return floor.content
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            headLine
            content
            bottomLine
        }
        .environmentObject(model)
    }
    
    private var headLine: some View {
        HStack {
            THPosterView(name: floor.posterName,
                         isPoster: model.isPoster)
            if !model.floor.spetialTag.isEmpty {
                THSpecialTagView(content: floor.spetialTag)
            }
            Spacer()
            THFloorActions()
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
            let floor = model.floor
            
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

struct THFloorActions: View {
    @EnvironmentObject var holeModel: THHoleModel
    @EnvironmentObject var model: THFloorModel
    
    @State var showReplySheet = false
    @State var showReportSheet = false
    @State var showSelectionSheet = false
    @State var showEditSheet = false
    @State var showHistorySheet = false
    @State var showDeleteAlert = false
    @State var showDeleteSheet = false
    @State var showRemoveSheet = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            if !model.floor.deleted {
                likeButton
                replyButton
            }
            
            if !model.floor.deleted || DXModel.shared.isAdmin {
                menu
            }
        }
        .sheet(isPresented: $showReportSheet) {
            THReportSheet()
        }
        .sheet(isPresented: $showSelectionSheet) {
            TextSelectionView(text: model.floor.content)
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
            } label: {
                HStack(alignment: .center, spacing: 3) {
                    Image(systemName: floor.liked ? "heart.fill" : "heart")
                    Text(String(floor.like))
                }
                .foregroundColor(floor.liked ? .pink : .secondary)
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
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
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .imageScale(.large)
                .font(.body)
                .foregroundColor(.secondary)
        }
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
    
    enum ReferenceType: Identifiable {
        case text(content: String)
        case local(floor: THFloor)
        case remote(mention: THMention)
        
        var id: UUID {
            UUID()
        }
    }
    
    func parse() -> [ReferenceType] {
        let floors = holeModel?.floors ?? []
        let mentions = floorModel?.floor.mention ?? []
        
        var partialContent = self.content
        var parsedElements: [ReferenceType] = []
        
        while let match = partialContent.firstMatch(of: /(?<prefix>#{1,2})(?<id>\d+)/) {
            // first part of text
            let previous = String(partialContent[partialContent.startIndex..<match.range.lowerBound])
            if !previous.isEmpty {
                parsedElements.append(.text(content: previous))
            }
            
            // match
            if match.prefix == "##" { // floor match
                let floorId = Int(match.id)
                if let floor = floors.filter({ $0.id == floorId }).first {
                    parsedElements.append(.local(floor: floor))
                } else if let mention = mentions.filter({ $0.floorId == floorId }).first {
                    parsedElements.append(.remote(mention: mention))
                }
            } else {
                let holeId = Int(match.id)
                if let mention = mentions.filter({ $0.holeId == holeId }).first {
                    parsedElements.append(.remote(mention: mention))
                }
            }
            
            // cut
            partialContent = String(partialContent[match.range.upperBound..<partialContent.endIndex])
        }
        
        if !partialContent.isEmpty {
            parsedElements.append(.text(content: partialContent))
        }
        
        return parsedElements
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            let elements = parse()
            
            ForEach(elements) { element in
                switch element {
                case .text(let content):
                    MarkdownView(content)
                case .local(let floor):
                    if interactable {
                        THLocalMentionView(floor)
                    } else {
                        THMentionView(floor: floor)
                    }
                case .remote(let mention):
                    THMentionView(mention: mention)
                }
            }
        }
    }
}
