import SwiftUI

struct FloorView: View {
    @State var floor: THFloor
    var isPoster: Bool
    let interactable: Bool
    
    @State var showReplyPage = false
    @State var showEditPage = false
    @State var showDeleteAlert = false
    @State var showRemoveAlert = false
    @State var showRemoveSheet = false
    @State var showReportSheet = false
    
    @ObservedObject var holeViewModel: HoleDetailViewModel
    var proxy: ScrollViewProxy? = nil
    
    @State var mentionNavigationActive = false
    @State var mentionFloorId = 0
    
    init(floor: THFloor, interactable: Bool = true) {
        self._floor = State(initialValue: floor)
        isPoster = false
        self.interactable = interactable
        self.holeViewModel = HoleDetailViewModel()
    }
    
    init(floor: THFloor, isPoster: Bool) {
        self._floor = State(initialValue: floor)
        self.isPoster = isPoster
        interactable = true
        self.holeViewModel = HoleDetailViewModel()
    }
    
    init(floor: THFloor,
         isPoster: Bool,
         model: HoleDetailViewModel,
         proxy: ScrollViewProxy) {
        self._floor = State(initialValue: floor)
        self.isPoster = isPoster
        self.holeViewModel = model
        self.proxy = proxy
        interactable = true
    }
    
    func like() {
        Task {
            do {
                let newFloor = try await NetworkRequests.shared.like(floorId: floor.id, like: !(floor.liked))
                self.floor = newFloor
                haptic()
            } catch {
                print("DANXI-DEBUG: like failed")
            }
        }
    }
    
    func delete(reason: String = "") {
        Task {
            do {
                let newFloor = try await NetworkRequests.shared.deleteFloor(floorId: floor.id, reason: reason)
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
                                         leading: -1,
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
    
    private var floorBody: some View {
        VStack(alignment: .leading) {
            HStack {
                poster
                if !floor.spetialTag.isEmpty {
                    SpecialTagView(content: floor.spetialTag)
                }
                Spacer()
                
                if !floor.deleted && interactable {
                    actions
                }
            }
            
            if floor.deleted {
                Text(floor.history.first?.content ?? "NONE")
                    .font(.system(size: 16))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                if holeViewModel.floors.isEmpty, let hole = holeViewModel.hole {
                    ReferenceView(floor.content,
                                  proxy: proxy,
                                  mentions: floor.mention,
                                  floors: hole.floors)
                } else {
                    ReferenceView(floor.content,
                                  proxy: proxy,
                                  mentions: floor.mention,
                                  floors: holeViewModel.floors)
                }
            }
            
            info
        }
        .sheet(isPresented: $showReplyPage) {
            ReplyPage(
                holeId: floor.holeId,
                content: "##\(String(floor.id))\n",
                floors: holeViewModel.floors,
                endReached: $holeViewModel.endReached)
        }
        .sheet(isPresented: $showEditPage) {
            EditReplyPage(
                floor: $floor,
                content: floor.content)
        }
        .sheet(isPresented: $showReportSheet, content: {
            ReportForm(floor: floor)
        })
        .alert("Delete Floor", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                delete()
            }
        } message: {
            Text("This floor will be deleted")
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
            
            Menu {
                menu
            } label: {
                Image(systemName: "ellipsis.circle")
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
                showReportSheet = true
            } label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            }
            
            Button {
                UIPasteboard.general.string = floor.content.stripToBasicMarkdown() // TODO: Is this format suitable for copy?
            } label: {
                Label("Copy Full Text", systemImage: "doc.on.doc")
            }
            
            if floor.isMe && !floor.deleted {
                Divider()
                
                Button {
                    showEditPage = true
                } label: {
                    Label("Edit Reply", systemImage: "square.and.pencil")
                }
                
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if TreeholeDataModel.shared.isAdmin {
                Divider()
                
                Menu {
                    Button {
                        // TODO: modify this floor
                    } label: {
                        Label("Modify Floor", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showRemoveAlert = true
                    } label: {
                        Label("Remove Floor", systemImage: "xmark.square")
                    }
                    
                    Button(role: .destructive) {
                        // TODO: ban user
                    } label: {
                        Label("Ban User", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Label("Admin Actions", systemImage: "person.badge.key")
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
