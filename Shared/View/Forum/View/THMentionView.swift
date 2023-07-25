import SwiftUI
import Foundation

// MARK: - Basic Mention View

struct THMentionView: View {
    @Environment(\.colorScheme) var colorScheme
    let mention: Mention
    
    init(floor: THFloor) {
        self.mention = Mention(floor)
    }
    
    init(mention: THMention) {
        self.mention = Mention(mention)
    }
    
    /// A struct unifying `THFloor` and `THMention`, only for UI rendering purpose.
    struct Mention {
        let id: Int
        let posterName: String
        let content: String
        let updateTime: Date
        let deleted: Bool
        
        init(_ floor: THFloor) {
            self.id = floor.id
            self.posterName = floor.posterName
            self.content = floor.content
            self.updateTime = floor.updateTime
            self.deleted = floor.deleted
        }
        
        init(_ mention: THMention) {
            self.id = mention.floorId
            self.posterName = mention.posterName
            self.content = mention.content
            self.updateTime = mention.updateTime
            self.deleted = mention.deleted
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .frame(width: 3, height: 15)
                
                Text(mention.posterName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "quote.closing")
                    .foregroundColor(.secondary)
            }
            .foregroundColor(randomColor(mention.posterName))
            
            Text(mention.content.inlineAttributed())
                .foregroundColor(mention.deleted ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .font(.subheadline)
                .lineLimit(3)
            
            HStack {
                Text("##\(String(mention.id))")
                Spacer()
                Text(mention.updateTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 1.0)
        }
        .padding(.horizontal)
        .padding(.vertical, 7.0)
        .background(Color.secondary.opacity(colorScheme == .light ? 0.1 : 0.2))
        .cornerRadius(7.0)
    }
}

// MARK: - Wrapper View

struct THLocalMentionView: View {
    @EnvironmentObject var model: THHoleModel
    
    let floor: THFloor
    
    init(_ floor: THFloor) {
        self.floor = floor
    }
    
    var body: some View {
        Button {
            model.scrollTarget = floor.id
        } label: {
            THMentionView(floor: floor)
        }
        .buttonStyle(.borderless) // prevent multiple tapping
    }
}

struct THRemoteMentionView: View {
    @EnvironmentObject private var model: THNavigator
    let mention: THMention
    
    var body: some View {
        Button {
            var loader = THHoleLoader()
            loader.holeId = mention.holeId
            loader.floorId = mention.floorId
            model.path.append(loader)
        } label: {
            THMentionView(mention: mention)
        }
        .buttonStyle(.borderless)
    }
}
