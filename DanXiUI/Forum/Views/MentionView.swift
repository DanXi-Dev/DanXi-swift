import SwiftUI
import ViewUtils
import DanXiKit

struct MentionView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let id: Int
    private let anonyname: String
    private let content: String
    private let timeUpdated: Date
    private let deleted: Bool
    
    init(_ floor: Floor) {
        self.id = floor.id
        self.anonyname = floor.anonyname
        self.content = floor.content
        self.timeUpdated = floor.timeUpdated
        self.deleted = floor.deleted
    }
    
    init(_ mention: Mention) {
        self.id = mention.floorId
        self.anonyname = mention.anonyname
        self.content = mention.content
        self.timeUpdated = mention.timeUpdated
        self.deleted = mention.deleted
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .frame(width: 3, height: 15)
                            
                Text(anonyname)
                    .font(.subheadline)
                    .fontWeight(.bold)
                            
                Spacer()
                            
                Image(systemName: "quote.closing")
                    .foregroundColor(.secondary)
            }
            .foregroundColor(randomColor(anonyname))
                        
            Text(content.inlineAttributed())
                .foregroundColor(deleted ? .secondary : .primary)
                .relativeLineSpacing(.em(0.18))
                .multilineTextAlignment(.leading)
                .font(.subheadline)
                .lineLimit(3)
                        
            HStack {
                Text(verbatim: "##\(String(id))")
                Spacer()
                Text(timeUpdated.formatted(.relative(presentation: .named, unitsStyle: .wide)))
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 1.0)
        }
        .padding(.horizontal, 12.0)
        .padding(.vertical, 7.0)
        .background(Color.secondary.opacity(colorScheme == .light ? 0.1 : 0.2))
        .cornerRadius(7.0)
    }
}

struct LocalMentionView: View {
    @EnvironmentObject private var model: HoleModel
    @Environment(\.originalFloor) private var originalFloor
    
    private let floor: Floor
    
    init(_ floor: Floor) {
        self.floor = floor
    }
    
    var body: some View {
        Button {
            model.scrollTo(floorId: floor.id)
            withAnimation(.spring(bounce: 0.55).speed(1.5)) {
                model.scrollFrom = originalFloor
            }
        } label: {
            MentionView(floor)
        }
        .buttonStyle(.borderless) // prevent multiple tapping
    }
}

struct RemoteMentionView: View {
    private let mention: Mention
    private let loader: HoleLoader
    
    init(_ mention: Mention) {
        self.mention = mention
        var loader = HoleLoader()
        loader.holeId = mention.holeId
        loader.floorId = mention.floorId
        self.loader = loader
    }
    
    var body: some View {
        DetailLink(value: loader, replace: false) {
            MentionView(mention)
        }
        .buttonStyle(.borderless)
    }
}
