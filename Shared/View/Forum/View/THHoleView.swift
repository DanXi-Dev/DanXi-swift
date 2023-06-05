import SwiftUI
import WrappingHStack

struct THHoleView: View {
    @Environment(\.colorScheme) var colorScheme

    @State var expand = false
    let hole: THHole
    let fold: Bool
    
    init(hole: THHole, fold: Bool = false) {
        self.hole = hole
        self.fold = fold
    }
    
    var body: some View {
        Group {
            if !fold || expand {
                fullContent
            } else {
                Button {
                    withAnimation {
                        expand.toggle()
                    }
                } label: {
                    tags
                }
            }
        }
    }
    
    private var fullContent: some View {
        NavigationListRow(value: hole) {
            VStack(alignment: .leading) {
                tags
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
            if !hole.firstFloor.spetialTag.isEmpty {
                HStack {
                    Spacer()
                    THSpecialTagView(content: hole.firstFloor.spetialTag)
                }
            }
            
            let firstFloorContent = hole.firstFloor.fold.isEmpty ? hole.firstFloor.content : hole.firstFloor.fold
            
            Text(firstFloorContent.inlineAttributed())
                .font(.callout)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .transition(.slide)
            
            if hole.firstFloor.id != hole.lastFloor.id {
                lastFloor
            }
            
            info
        }
    }
    
    private var tags: some View {
        WrappingHStack(alignment: .leading) {
            ForEach(hole.tags) { tag in
                THTagView(tag)
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
            Text(hole.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
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
            Image(systemName: "arrowshape.turn.up.left.fill")
            
            VStack(alignment: .leading, spacing: 3) {
                Text("\(hole.lastFloor.posterName) replied \(hole.lastFloor.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide))):")
                    .font(.custom("", size: 12))
                    .fixedSize(horizontal: false, vertical: true)
                
                let lastFloorContent = hole.lastFloor.fold.isEmpty ? hole.lastFloor.content : hole.lastFloor.fold
                
                Text(lastFloorContent.inlineAttributed())
                    .lineLimit(1)
                    .font(.custom("", size: 14))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .foregroundColor(.secondary)
        .padding(10)
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.1))
        .cornerRadius(7)
    }
}

fileprivate struct THHolePreview: View {
    @StateObject var model: THHoleModel
    
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

fileprivate struct PreviewActions: View {
    @ObservedObject var appModel = DXModel.shared
    @ObservedObject var settings = THSettings.shared
    
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
