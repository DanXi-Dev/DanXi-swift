import SwiftUI
import Foundation

struct MentionView: View {
    let floor: THFloor
    
    let mentionType: MentionType
    let proxy: ScrollViewProxy?
    
    @State var navigationActive = false
    
    enum MentionType {
        case local
        case remote
    }
    
    init(floor: THFloor, proxy: ScrollViewProxy? = nil) {
        self.floor = floor
        self.proxy = proxy
        self.mentionType = .local
    }
    
    init(mention: THMention) {
        self.floor = THFloor(id: mention.floorId, holeId: mention.holeId,
                             updateTime: mention.updateTime, createTime: mention.createTime,
                             like: 0, liked: false, isMe: false,
                             deleted: mention.deleted,
                             storey: 0,
                             content: mention.content, posterName: mention.posterName,
                             spetialTag: "", mention: [], history: [])
        self.proxy = nil
        self.mentionType = .remote
    }
    
    var body: some View {
        switch mentionType {
            
        case .local:
            Button {
                if let proxy = proxy {
                    withAnimation {
                        proxy.scrollTo(floor.id, anchor: .top)
                    }
                }
            } label: {
                mention
            }
            .buttonStyle(.borderless) // prevent multiple tapping
            #if os(iOS)
            // TODO: use geometry reader to determine size
            .previewContextMenu(preview: ScrollView { FloorView(floor: floor).padding() }) {
                PreviewContextAction(title: Bundle.main.localizedString(forKey: "Locate", value: nil, table: nil),
                                     systemImage: "arrow.right.square") {
                    if let proxy = proxy {
                        withAnimation {
                            proxy.scrollTo(floor.id, anchor: .top)
                        }
                    }
                }
            }
            #endif
            
            
        case .remote:
            Button {
                navigationActive = true
            } label: {
                mention
                    .background(navigation)
            }
            .buttonStyle(.borderless) // prevent multiple tapping
            #if os(iOS)
            // TODO: use geometry reader to determine size
            .previewContextMenu(destination: ScrollView { FloorView(floor: floor).padding() },
                                preview: FloorView(floor: floor).padding())
            #endif
        }
    }
    
    private var mention: some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .frame(width: 3, height: 15)
                
                Text(floor.posterName)
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "quote.closing")
                    .foregroundColor(.secondary)
            }
            .foregroundColor(randomColor(name: floor.posterName))
            
            Text(floor.content.inlineAttributed())
                .foregroundColor(floor.deleted ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .font(.system(size: 15))
                .lineLimit(3)
            
            HStack {
                Text("#\(String(floor.id))")
                Spacer()
                Text(floor.updateTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 1.0)
        }
        .padding(.horizontal)
        .padding(.vertical, 7.0)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(7.0)
    }
    
    private var navigation: some View {
        NavigationLink("", destination: HoleDetailPage(targetFloorId: floor.id), isActive: $navigationActive)
            .opacity(0)
    }
}

struct MentionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MentionView(floor: PreviewDecode.decodeObj(name: "floor")!)
            
            MentionView(floor: PreviewDecode.decodeObj(name: "floor")!)
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        
    }
}
