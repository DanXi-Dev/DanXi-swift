import SwiftUI

struct FloorView: View {
    @State var floor: THFloor
    var isPoster: Bool
    
    @State var showReplyPage = false
    @State var showEditPage = false
    var holeViewModel: HoleDetailViewModel? = nil
    var proxy: ScrollViewProxy? = nil
    
    @State var mentionNavigationActive = false
    @State var mentionFloorId = 0
    
    init(floor: THFloor) {
        self._floor = State(initialValue: floor)
        isPoster = false
    }
    
    init(floor: THFloor, isPoster: Bool) {
        self._floor = State(initialValue: floor)
        self.isPoster = isPoster
    }
    
    init(floor: THFloor, isPoster: Bool, model: HoleDetailViewModel, proxy: ScrollViewProxy) {
        self._floor = State(initialValue: floor)
        self.isPoster = isPoster
        self.holeViewModel = model
        self.proxy = proxy
    }
    
    func like() {
        Task {
            do {
                let newFloor = try await NetworkRequests.shared.like(floorId: floor.id, like: !(floor.liked))
                self.floor = newFloor
            } catch {
                print("DANXI-DEBUG: like failed")
            }
        }
    }
    
    func delete() {
        Task {
            do {
                let newFloor = try await NetworkRequests.shared.deleteFloor(floorId: floor.id)
                self.floor = newFloor
            } catch {
                print("DANXI-DEBUG: delete failed")
            }
        }
    }
    
    var body: some View {
        if floor.deleted {
            DisclosureGroup {
                floorBody
                    .listRowSeparator(.hidden, edges: .top)
                    .listRowInsets(.init(top: 0,
                                         leading: 0,
                                         bottom: 5,
                                         trailing: 15))
            } label: {
                Text(floor.content)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        } else {
            floorBody
        }
    }
    
    @MainActor
    private var floorBody: some View {
        VStack(alignment: .leading) {
            HStack {
                poster
                if !floor.spetialTag.isEmpty {
                    SpecialTagView(content: floor.spetialTag)
                }
                Spacer()
                
                if !floor.deleted {
                    actions
                }
            }
            
            renderedContent(floor.content)
            
            info
        }
        .sheet(isPresented: $showReplyPage) {
            ReplyPage(
                holeId: floor.holeId,
                content: "##\(String(floor.id))\n")
        }
        .sheet(isPresented: $showEditPage) {
            EditReplyPage(
                floor: $floor,
                content: floor.content)
        }
    }
    
    @MainActor
    private func renderedContent(_ content: String) -> some View {
        let contentElements = parseMarkdownReferences(floor.content,
                                                      mentions: floor.mention,
                                                      holeModel: holeViewModel)
        
        return VStack(alignment: .leading, spacing: 7) {
            ForEach(contentElements) { element in
                switch element {
                case .text(let content):
                    MarkdownView(content)
                        .textSelection(.enabled)
                    
                case .localReference(let floor):
                    MentionView(floor: floor, proxy: proxy)
                    
                case .remoteReference(let mention):
                    MentionView(mention: mention)
                    
                case .reference(let floorId):
                    Text("NOT SUPPOTED MENTION: \(String(floorId))")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var poster: some View {
        HStack {
            Rectangle()
                .frame(width: 3, height: 15)
            
            if isPoster {
                Text("DZ")
                    .font(.system(size: 13))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6.0)
                    .background(randomColor(name: floor.posterName))
                    .cornerRadius(3.0)
            }
            
            Text(floor.posterName)
                .font(.system(size: 15))
                .fontWeight(.bold)
        }
        .foregroundColor(randomColor(name: floor.posterName))
    }
    
    private var info: some View {
        HStack {
            Text("\(floor.storey + 1)F")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text("(##\(String(floor.id)))")
                .font(.caption2)
            
            Spacer()
            
            if floor.deleted {
                Text("Deleted")
            } else if floor.edited {
                Text("Edited")
            }
            
            Spacer()
            
            Text(floor.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
        }
        .font(.caption)
        .foregroundColor(Color.secondary.opacity(0.7))
        .padding(.top, 2.0)
    }
    
    private var actions: some View {
        HStack(alignment: .center, spacing: 20) {
            Button(action: like) {
                HStack(alignment: .center, spacing: 3) {
                    Image(systemName: floor.liked ? "heart.fill" : "heart")
                    Text(String(floor.like))
                }
                .foregroundColor(floor.liked ? .pink : .secondary)
            }
            
            Button {
                showReplyPage = true
            } label: {
                Image(systemName: "arrowshape.turn.up.left")
            }
            
            if floor.isMe && !floor.deleted {
                Button(action: delete) {
                    Image(systemName: "trash")
                }
            }
            
            Menu {
                menu
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .buttonStyle(.borderless) // prevent multiple tapping
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.trailing, 10)
    }
    
    private var menu: some View {
        Group {
            Button {
                // TODO: report
            } label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            }
            
            Button {
                UIPasteboard.general.string = floor.content.stripToBasicMarkdown() // TODO: Is this format suitable for copy?
            } label: {
                Label("Copy Full Text", systemImage: "doc.on.doc")
            }
            
            Button {
                UIPasteboard.general.string = "##\(String(floor.id))"
            } label: {
                Label("Copy Floor ID", systemImage: "doc.on.doc")
            }
            
            if floor.isMe && !floor.deleted {
                Button {
                    showEditPage = true
                } label: {
                    Label("Edit reply", systemImage: "square.and.pencil")
                }
            }
        }
    }
}

struct FloorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            
            FloorView(floor: PreviewDecode.decodeObj(name: "floor")!, isPoster: true)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Floor")
            
            FloorView(floor: PreviewDecode.decodeObj(name: "floor")!)
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Floor Dark")
            
            FloorView(floor: PreviewDecode.decodeObj(name: "deleted-floor")!)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Deleted Floor")
            
            FloorView(floor: PreviewDecode.decodeObj(name: "long-floor")!)
                .previewDisplayName("Long Floor")
            
            ScrollView {
                FloorView(floor: PreviewDecode.decodeObj(name: "styled-floor")!)
            }
            .previewDisplayName("Styled Floor")
        }
        .padding()
    }
}
