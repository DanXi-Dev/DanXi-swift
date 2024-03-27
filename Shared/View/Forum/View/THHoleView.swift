import SwiftUI
import ViewUtils
import WrappingHStack

struct THHoleView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var expand = false
    let hole: THHole
    let fold: Bool
    let pinned: Bool
    
    init(hole: THHole, fold: Bool = false, pinned: Bool = false) {
        self.hole = hole
        self.fold = fold
        self.pinned = pinned
    }
    
    var body: some View {
        FoldedView(expand: !fold) {
            HStack(alignment: .center) {
                Spacer()
                Text("Folded")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .fontWeight(.light)
                    .padding(.leading, 3)
                    .padding(.top, 1)
                    .fixedSize()
            }
            .background(alignment: .leading) {
                HStack {
                    tags
                        .fixedSize()
                }
                .clipped()
            }
            
        } content: {
            fullContent
        }
    }
    
    private var fullContent: some View {
        NavigationListRow(value: hole) {
            VStack(alignment: .leading) {
                tags
                    .padding(.bottom, 3)
                holeContent
            }
        }
        .contextMenu {
            PreviewActions(hole: hole)
        } preview: {
            THHolePreview(hole, hole.floors)
        }
    }
    
    private var holeContent: some View {
        Group {
            let firstFloorContent = hole.firstFloor.fold.isEmpty ? hole.firstFloor.content : hole.firstFloor.fold
            
            Text(firstFloorContent.inlineAttributed())
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .padding(.leading, 3)
            
            if hole.firstFloor.id != hole.lastFloor.id {
                lastFloor
                    .padding(.vertical, 1)
                    .padding(.leading, 10)
            }
            
            info
        }
    }
    
    private var tags: some View {
        HStack(alignment: .top) {
            WrappingHStack(alignment: .leading) {
                ForEach(hole.tags) { tag in
                    THTagView(tag)
                }
            }
            
            if !hole.firstFloor.spetialTag.isEmpty {
                Spacer()
                HStack {
                    THSpecialTagView(content: hole.firstFloor.spetialTag)
                    if pinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
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
            Text(hole.createTime.autoFormatted())
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
            VStack(alignment: .leading, spacing: 3) {
                Text("\(hole.lastFloor.posterName) replied \(hole.lastFloor.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide))):")
                    .font(.custom("", size: 12))
                    .fixedSize(horizontal: false, vertical: true)
                
                let lastFloorContent = hole.lastFloor.fold.isEmpty ? hole.lastFloor.content : hole.lastFloor.fold
                
                Text(lastFloorContent.inlineAttributed())
                    .lineLimit(1)
                    .font(.custom("", size: 14))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .foregroundColor(.secondary)
        .padding(.leading, 8)
        .overlay(alignment: .leading) {
            Rectangle()
                .frame(width: 3, height: nil)
                .padding(.top, 2)
                .foregroundStyle(.secondary.opacity(0.5))
        }
        
//        .background(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.1))
//        .cornerRadius(7)
    }
}

private struct THHolePreview: View {
    @StateObject private var model: THHoleModel
    
    init(_ hole: THHole, _ floors: [THFloor]) {
        let model = THHoleModel(hole: hole, floors: floors)
        model.endReached = true
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        List {
            ForEach(model.floors) { floor in
                THComplexFloor(floor)
            }
        }
        .listStyle(.inset)
        .environmentObject(model)
    }
}

private struct PreviewActions: View {
    @ObservedObject private var appModel = THModel.shared
    @ObservedObject private var settings = THSettings.shared
    
    let hole: THHole
    
    var body: some View {
        Group {
            AsyncButton {
                try await appModel.toggleFavorite(hole.id)
                haptic()
            } label: {
                Group {
                    if !appModel.isFavorite(hole.id) {
                        Label("Add to Favorites", systemImage: "star")
                    } else {
                        Label("Remove from Favorites", systemImage: "star.slash")
                    }
                }
            }
            
            AsyncButton {
                if appModel.isSubscribed(hole.id) {
                    try await appModel.deleteSubscription(hole.id)
                } else {
                    try await appModel.addSubscription(hole.id)
                }
                haptic()
            } label: {
                if appModel.isSubscribed(hole.id) {
                    Label("Unsubscribe", systemImage: "bell.slash")
                } else {
                    Label("Subscribe", systemImage: "bell")
                }
            }
            
            Button {
                if !settings.blockedHoles.contains(hole.id) {
                    withAnimation {
                        settings.blockedHoles.append(hole.id)
                    }
                }
            } label: {
                Label("Don't Show This Hole", systemImage: "eye.slash")
            }
        }
    }
}
