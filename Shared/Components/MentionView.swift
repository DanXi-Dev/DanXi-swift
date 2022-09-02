import SwiftUI

struct MentionView: View {
    let poster: String
    let content: String
    let floorId: Int
    let date: Date
    let deleted: Bool
    
    let mentionType: MentionType
    let proxy: ScrollViewProxy?
    
    @State var navigationActive = false
    
    enum MentionType {
        case local
        case remote
    }
    
    init(floor: THFloor, proxy: ScrollViewProxy? = nil) {
        self.poster = floor.posterName
        self.content = floor.content
        self.floorId = floor.id
        self.date = floor.createTime
        self.proxy = proxy
        self.deleted = floor.deleted
        self.mentionType = .local
    }
    
    init(mention: THMention) {
        self.poster = mention.posterName
        self.content = mention.content
        self.floorId = mention.floorId
        self.date = mention.createTime
        self.proxy = nil
        self.deleted = mention.deleted
        self.mentionType = .remote
    }
    
    var body: some View {
        switch mentionType {
            
        case .local:
            Button {
                if let proxy = proxy {
                    withAnimation {
                        proxy.scrollTo(floorId, anchor: .top)
                    }
                }
            } label: {
                mention
            }
            .buttonStyle(.borderless) // prevent multiple tapping
            
        case .remote:
            Button {
                navigationActive = true
            } label: {
                mention
                    .background(navigation)
            }
            .buttonStyle(.borderless) // prevent multiple tapping
        }
    }
    
    private var mention: some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .frame(width: 3, height: 15)
                
                Text(poster)
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "quote.closing")
                    .foregroundColor(.secondary)
            }
            .foregroundColor(randomColor(name: poster))
            
            Text(content.inlineAttributed())
                .foregroundColor(deleted ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .font(.system(size: 15))
                .lineLimit(3)
            
            HStack {
                Text("#\(String(floorId))")
                Spacer()
                Text(date.formatted(.relative(presentation: .named, unitsStyle: .wide)))
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
        NavigationLink("", destination: HoleDetailPage(targetFloorId: floorId), isActive: $navigationActive)
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
