import SwiftUI
import ViewUtils
import DanXiKit

struct MentionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded: Bool = false
    
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
            HStack(alignment: .firstTextBaseline) {
                Rectangle()
                    .frame(width: 2.5, height: 11.5)
                            
                Text(anonyname)
                    .fontWeight(.semibold)
                Text(timeUpdated.formatted(.relative(presentation: .named, unitsStyle: .wide)))
                    .foregroundColor(.secondary)
                    .font(.caption)
                            
                Spacer()
                            
                Image(systemName: isExpanded ? "quote.opening" : "quote.closing")
                    .foregroundColor(.secondary)
            }
            .foregroundColor(randomColor(anonyname))
            .font(.subheadline)
                        
            Text(inlineAttributed(content))
                .foregroundColor(deleted ? .secondary : .primary)
                .relativeLineSpacing(.em(0.18))
                .multilineTextAlignment(.leading)
                .font(.subheadline)
                .lineLimit(isExpanded ? nil : 1)
        }
        .padding(.horizontal, 12.0)
        .padding(.top, 6.5)
        .padding(.bottom, 8.0)
        .background(Color.secondary.opacity(colorScheme == .light ? 0.1 : 0.2))
        .cornerRadius(7.0)
        .onLongPressGesture(minimumDuration: 0.2) {
                isExpanded.toggle()
        }
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
            withAnimation(.spring(bounce: 0.3).speed(1.8)) {
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
