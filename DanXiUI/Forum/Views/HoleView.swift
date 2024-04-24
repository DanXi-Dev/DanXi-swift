import SwiftUI
import ViewUtils
import DanXiKit

struct HoleView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var favoriteStore = FavoriteStore.shared
    @ObservedObject private var subscriptionStore = SubscriptionStore.shared
    @ObservedObject private var settings = ForumSettings.shared
    
    private let hole: Hole
    private let fold: Bool
    private let pinned: Bool
    
    init(hole: Hole, fold: Bool = false, pinned: Bool = false) {
        self.hole = hole
        self.fold = fold
        self.pinned = pinned
    }
    
    var body: some View {
        FoldedView(expand: !fold) {
            HStack(alignment: .center) {
                ScrollView(.horizontal, showsIndicators: false) {
                    tags
                }
                .allowsHitTesting(false)
                Spacer()
                Text("Folded")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .fontWeight(.light)
                    .fixedSize()
            }
        } content: {
            fullContent
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 9, bottom: 8, trailing: 9))
    }
    
    private var fullContent: some View {
        DetailLink(value: hole) {
            VStack(alignment: .leading) {
                tags
                    .padding(.bottom, 3.6)
                holeContent
            }
        }
        .contextMenu {
            previewActions
        } preview: {
            HolePreview(hole, hole.prefetch)
        }
    }
    
    @ViewBuilder
    private var previewActions: some View {
        AsyncButton {
            try await withHaptics {
                try await favoriteStore.toggleFavorite(hole.id)
            }
        } label: {
            Group {
                if favoriteStore.isFavorite(hole.id) {
                    Label("Unfavorite", systemImage: "star.slash")
                } else {
                    Label("Favorite", systemImage: "star")
                }
            }
        }
            
        AsyncButton {
            try await withHaptics {
                try await subscriptionStore.toggleSubscription(hole.id)
            }
        } label: {
            if subscriptionStore.isSubscribed(hole.id) {
                Label("Unsubscribe", systemImage: "bell.slash")
            } else {
                Label("Subscribe", systemImage: "bell")
            }
        }
            
        Divider()
            
        Button(role: .destructive) {
            if !settings.blockedHoles.contains(hole.id) {
                withAnimation {
                    settings.blockedHoles.append(hole.id)
                }
            }
        } label: {
            Label("Don't Show This Hole", systemImage: "eye.slash")
        }
    }
    
    private var holeContent: some View {
        Group {
            let firstFloorContent = hole.firstFloor.fold.isEmpty ? hole.firstFloor.content : hole.firstFloor.fold
            
            Text(firstFloorContent.inlineAttributed())
                .font(.callout)
                .relativeLineSpacing(.em(0.18))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .padding(.leading, 3)
                .padding(.trailing, 1)
            
            if hole.firstFloor.id != hole.lastFloor.id {
                lastFloor
                    .padding(.vertical, 1)
                    .padding(.leading, 8)
            }
            
            info
        }
    }
    
    private var tags: some View {
        HStack(alignment: .top) {
            WrappingHStack(alignment: .leading) {
                ForEach(hole.tags) { tag in
                    TagView(tag.name)
                }
            }
            Spacer()
            HStack {
                if !hole.firstFloor.specialTag.isEmpty {
                    SpecialTagView(content: hole.firstFloor.specialTag)
                }
                if pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var info: some View {
        HStack {
            Text("#\(String(hole.id))")
            if hole.hidden {
                Image(systemName: "eye.slash")
            }
            Spacer()
            Text(hole.timeCreated.autoFormatted())
            Spacer()
            actions
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.top, 3)
    }
    
    private var actions: some View {
        HStack(alignment: .center, spacing: 15) {
            HStack(alignment: .center, spacing: 3) {
                Image(systemName: "eye")
                Text(String(hole.view))
            }
            
            HStack(alignment: .center, spacing: 3) {
                Image(systemName: "ellipsis.bubble")
                Text(String(hole.reply))
            }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    
    private var lastFloor: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(hole.lastFloor.anonyname) replied \(hole.lastFloor.timeCreated.formatted(.relative(presentation: .named, unitsStyle: .wide))):")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                
                let lastFloorContent = hole.lastFloor.fold.isEmpty ? hole.lastFloor.content : hole.lastFloor.fold
                
                Text(lastFloorContent.inlineAttributed())
                    .lineLimit(1)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .foregroundColor(.secondary)
        .padding(.leading, 8)
        .overlay(alignment: .leading) {
            Rectangle()
                .frame(width: 2.8, height: nil)
                .padding(.top, 2)
                .foregroundStyle(.secondary.opacity(0.5))
                .tint(.primary)
        }
    }
}

private struct HolePreview: View {
    @StateObject private var model: HoleModel
    
    init(_ hole: Hole, _ floors: [Floor]) {
        let model = HoleModel(hole: hole, floors: floors)
        model.endReached = true
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        List {
            ForEach(model.floors) { floor in
                FloorView(presentation: floor)
            }
        }
        .listStyle(.inset)
        .environmentObject(model)
    }
}
