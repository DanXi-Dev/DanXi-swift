import SwiftUI

struct HoleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let hole: THHole
    let fold: Bool
    @ObservedObject var preference = Preference.shared

    enum NavigationType {
        case top
        case bottom
    }
    
    @State var navActive = false
    @State var navType = NavigationType.top
    
    init(hole: THHole, fold: Bool = false) {
        self.hole = hole
        self.fold = fold
    }
    
    var body: some View {
        if fold {
            DisclosureGroup {
                VStack(alignment: .leading) {
                    holeContent
                }
                .onTapGesture {
                    navType = .top
                    navActive = true
                }
                .background(NavigationLink("", destination: navTarget, isActive: $navActive).opacity(0))
                #if os(iOS)
                .previewContextMenu(destination: HoleDetailPage(hole: hole),
                                    preview: HoleDetailPage(hole: hole, floors: hole.floors))
                #endif
                .listRowSeparator(.hidden, edges: .top)
                .listRowInsets(.init(top: 0,
                                     leading: -1,
                                     bottom: 5,
                                     trailing: 15))
            } label: {
                TagList(hole.tags, lineWrap: false)
            }
        } else {
            VStack(alignment: .leading) {
                TagList(hole.tags, lineWrap: false)
                holeContent
            }
            .onTapGesture {
                navType = .top
                navActive = true
            }
            .background(NavigationLink("", destination: navTarget, isActive: $navActive).opacity(0))
            #if os(iOS)
            .previewContextMenu(destination: HoleDetailPage(hole: hole),
                                preview: HoleDetailPage(hole: hole, floors: hole.floors))
            #endif
        }
    }
    
    private var holeContent: some View {
        Group {
            if (preference.nlModelDebuggingMode) {
                // A preview for CoreML Model
                Text(TagPredictor.shared?.debugPredictTagForText(hole.firstFloor.content, modelId: 0) ?? "MaxEntropy NLModel init failed")
                    .foregroundColor(.green)
                Text(TagPredictor.shared?.debugPredictTagForText(hole.firstFloor.content, modelId: 1) ?? "TransferLearning NLModel init failed")
                    .foregroundColor(.red)
            }
            
            if !hole.firstFloor.spetialTag.isEmpty {
                HStack {
                    Spacer()
                    SpecialTagView(content: hole.firstFloor.spetialTag)
                }
            }
            
            Text(hole.firstFloor.content.inlineAttributed())
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .transition(.slide)
            
            if hole.firstFloor.id != hole.lastFloor.id {
                Button {
                    navType = .bottom
                    navActive = true
                } label: {
                    lastFloor
                }
                .buttonStyle(.borderless)
            }
            
            info
        }
    }
    
    private var info: some View {
        HStack {
            Text("#\(String(hole.id))")
            Spacer()
            Text(hole.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
            Spacer()
            actions
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .foregroundColor(Color(uiColor: .systemGray2))
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
            
            // TODO: maybe add menu?
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    
    private var lastFloor: some View {
        HStack(alignment: .top) {
            Image(systemName: "arrowshape.turn.up.left.fill")
            
            VStack(alignment: .leading, spacing: 3) {
                Text("\(hole.lastFloor.posterName) replied \(hole.lastFloor.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide))):")
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(hole.lastFloor.content.inlineAttributed())
                    .lineLimit(1)
                    .font(.system(size: 14))
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
    
    @ViewBuilder
    private var navTarget: some View {
        switch navType {
        case .top:
            HoleDetailPage(hole: hole)
        case .bottom:
            HoleDetailPage(targetFloorId: hole.lastFloor.id)
        }
    }
}

struct HoleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HoleView(hole: PreviewDecode.decodeObj(name: "hole")!)
            HoleView(hole: PreviewDecode.decodeObj(name: "hole")!)
                .preferredColorScheme(.dark)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
