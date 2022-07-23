import SwiftUI

struct THFloorView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let floor: THFloor
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                poster
                Spacer()
                actions
            }
            Text(floor.content)
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
                .foregroundColor(.secondary)
#if !os(watchOS)
                .foregroundColor(Color(uiColor: .systemGray2))
#endif
            
            Spacer()
            Text(floor.createTime.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
#if !os(watchOS)
                .foregroundColor(Color(uiColor: .systemGray2))
#endif
        }
        .padding(.top, 2.0)
    }
    
    private var actions: some View {
        HStack(alignment: .center, spacing: 15) {
            Button {
                // TODO: like
            } label: {
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
#if !os(watchOS)
            Menu {
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
            } label: {
                Image(systemName: "ellipsis")
            }
#endif
        }
        .padding(.top, 4.0)
        .font(.caption2)
        .foregroundColor(.secondary)
    }
}

struct THPost_Previews: PreviewProvider {
    
    static let floor = THFloor(
        id: 1234567,
        holeId: 123456,
        iso8601UpdateTime: "2022-04-14T08:23:12.761042+08:00",
        iso8601CreateTime: "2022-04-14T08:23:12.761042+08:00",
        updateTime: Date.now, createTime: Date.now,
        like: 12,
        liked: true,
        storey: 5,
        content: """
        Hello, **Dear** readers!
        
        We can make text *italic*, ***bold italic***, or ~~striked through~~.
        
        You can even create [links](https://www.twitter.com/twannl) that actually work.
        
        Or use `Monospace` to mimic `Text("inline code")`.
        
        """,
        posterName: "Dax")
    
    static var previews: some View {
        Group {
            THFloorView(floor: floor)
                .padding()
            THFloorView(floor: floor)
                .padding()
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
