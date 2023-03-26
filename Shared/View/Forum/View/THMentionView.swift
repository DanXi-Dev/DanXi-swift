import SwiftUI
import SwiftUIX
import Foundation

// MARK: - Basic Mention View

/// View that represents a mention to a floor, UI only, not interactable.
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

/// View that presents a local mention, scroll to target when tapped.
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

/// View that represents a remote mention, navigate to target when tapped.
struct THRemoteMentionView: View {
    @EnvironmentObject var model: THNavigationModel
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

/// Mention view that is not initialized, tap to load detailed info.
struct THLoadingMentionView: View {
    let floorId: Int
    @State var loading = false
    @State var floor: THFloor? = nil
    
    var body: some View {
        if let floor = floor {
            THMentionView(floor: floor)
        } else {
            Button {
                // FIXME: might not be reloaded in edit preview section
                Task { @MainActor in
                    do {
                        loading = true
                        floor = try await THRequests.loadFloorById(floorId: floorId)
                    } catch {
                        loading = false
                    }
                }
            } label: {
                previewPrompt
            }
            .buttonStyle(.borderless)
        }
    }
    
    var previewPrompt: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image(systemName: "quote.closing")
            }
            .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                if loading {
                    ProgressView()
                }
                Text(loading ? "Loading" : "Tap to view detail")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            
            Text("##\(String(floorId))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 1.0)
        }
        .padding(.horizontal)
        .padding(.vertical, 7.0)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(7.0)
    }
}

// MARK: - Environment Settings

struct THMentionProxy: EnvironmentKey {
    static let defaultValue: ScrollViewProxy? = nil
}

extension EnvironmentValues {
    var mentionProxy: ScrollViewProxy? {
        get { self[THMentionProxy.self] }
        set { self[THMentionProxy.self] = newValue }
    }
}

extension View {
    func mentionProxy(_ proxy: ScrollViewProxy) -> some View {
        environment(\.mentionProxy, proxy)
    }
}

// MARK: - Preview

struct THMentionView_Previews: PreviewProvider {
    static var previews: some View {
        THMentionView(floor: Bundle.main.decodeData("floor"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
