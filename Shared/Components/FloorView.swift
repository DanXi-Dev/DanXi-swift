import SwiftUI
import MarkdownUI

struct FloorView: View {
    @State var floor: THFloor
    var isPoster: Bool
    
    @State var showReplyPage = false
    @State var showEditPage = false
    var holeViewModel: HoleDetailViewModel? = nil
    var proxy: ScrollViewProxy? = nil
    
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
                let newFloor = try await NetworkRequests.shared.like(floorId: floor.id, like: !(floor.liked ?? false))
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
        VStack(alignment: .leading) {
            HStack {
                poster
                Spacer()
                actions
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
        
        return VStack(alignment: .leading) {
            ForEach(contentElements) { element in
                switch element {
                case .text(let content):
                    Markdown(content)
                        .markdownStyle(MarkdownStyle(font: .system(size: 16)))
                        .textSelection(.enabled)
                    
                case .localReference(let floor):
                    Menu(content: {
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
                        Button {
                            // TODO: Not implemented
                        } label: {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                        }
                        
                        if let proxy = proxy {
                            Button {
                                withAnimation {
                                    proxy.scrollTo(floor.id, anchor: .top)
                                }
                            } label: {
                                Label("Locate", systemImage: "arrow.right.square")
                            }
                        }
                    }, label: {
                        MentionView(floor: floor)
                    })
                    
                case .remoteReference(let mention):
                    MentionView(mention: mention)
                    
                case .reference(let floorId):
                    Text(String(floorId))
                        .foregroundColor(.green)
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
                .foregroundColor(Color(uiColor: .systemGray2))
            
            Spacer()
            Text(floor.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
                .font(.caption)
                .foregroundColor(Color(uiColor: .systemGray2))
            
        }
        .padding(.top, 2.0)
    }
    
    private var actions: some View {
        HStack(alignment: .center, spacing: 30) {
            Button(action: like) {
                HStack(alignment: .center, spacing: 3) {
                    Image(systemName: floor.liked ?? false ? "heart.fill" : "heart")
                    Text(String(floor.like))
                }
                .foregroundColor(floor.liked ?? false ? .pink : .secondary)
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
