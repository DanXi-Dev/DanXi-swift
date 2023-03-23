import SwiftUI

struct THComplexFloor: View {
    @StateObject var model: THFloorModel
    
    init(_ floor: THFloor, context: THHoleModel) {
        let model = THFloorModel(floor: floor, context: context)
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            headLine
            THFloorContent()
            bottomLine
        }
        .environmentObject(model)
    }
    
    private var headLine: some View {
        HStack {
            THPosterView(name: model.floor.posterName,
                         isPoster: model.isPoster)
            Spacer()
            THFloorActions()
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
    @EnvironmentObject var model: THFloorModel
    
    @State var showReplySheet = false
    @State var showReportSheet = false
    @State var showSelectionSheet = false
    @State var showHistorySheet = false
    @State var showDeleteAlert = false
    @State var showDeleteSheet = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            likeButton
            replyButton
            menu
        }
        .buttonStyle(.borderless)
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.trailing, 10)
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
        }
    }
    
    private var replyButton: some View {
        Button {
            showReplySheet = true
        } label: {
            Image(systemName: "arrowshape.turn.up.left")
        }
        .sheet(isPresented: $showReplySheet) {
            Text("TODO: Reply Sheet")
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
                
            } label: {
                Label("Show This Person", systemImage: "message")
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
    @EnvironmentObject var holeModel: THHoleModel
    @EnvironmentObject var floorModel: THFloorModel
    
    enum ReferenceType: Identifiable {
        case text(content: String)
        case local(floor: THFloor)
        case remote(mention: THMention)
        
        var id: UUID {
            UUID()
        }
    }
    
    func parse() -> [ReferenceType] {
        let floors = holeModel.floors
        let mentions = floorModel.floor.mention
        
        var partialContent = floorModel.floor.content
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
                    THMentionView(floor: floor)
                case .remote(let mention):
                    THMentionView(mention: mention)
                }
            }
        }
    }
}
