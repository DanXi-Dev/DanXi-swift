import SwiftUI
import MarkdownUI

struct FloorView: View {
    @State var floor: THFloor
    
    func like() {
        Task {
            do {
                let newFloor = try await networks.like(floorId: floor.id, like: !(floor.liked ?? false))
                self.floor = newFloor
            } catch {
                print("DANXI-DEBUG: like failed")
            }
        }
    }
    
    func delete() {
        Task {
            do {
                let newFloor = try await networks.deleteFloor(floorId: floor.id)
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
            Markdown(floor.content)
                .font(.system(size: 16))
            info
        }
    }
    
    private var poster: some View {
        HStack {
            Rectangle()
                .frame(width: 3, height: 15)
            Text(floor.posterName)
                .font(.system(size: 15))
                .fontWeight(.bold)
        }
        .foregroundColor(.red)
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
            Text(floor.createTime.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(Color(uiColor: .systemGray2))

        }
        .padding(.top, 2.0)
    }
    
    private var actions: some View {
        HStack(alignment: .center, spacing: 15) {
            Button(action: like) {
                HStack(alignment: .center, spacing: 3) {
                    Image(systemName: floor.liked ?? false ? "heart.fill" : "heart")
                    Text(String(floor.like))
                }
                .foregroundColor(floor.liked ?? false ? .pink : .secondary)
            }
            
            Button {
                // TODO: reply
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
        .font(.caption2)
        .foregroundColor(.secondary)
        
    }
    
    private var menu: some View {
        Group {
            Button {
                // TODO: report
            } label: {
                Label("report", systemImage: "exclamationmark.triangle")
            }
            
            Button {
                // TODO: copy text
            } label: {
                Label("copy_full_text", systemImage: "doc.on.doc")
            }
            
            Button {
                // TODO: copy floor id
            } label: {
                Label("copy_floor_id", systemImage: "square.and.arrow.up")
            }
        }
    }
}

struct FloorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FloorView(floor: PreviewDecode.decodeObj(name: "floor")!)
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
