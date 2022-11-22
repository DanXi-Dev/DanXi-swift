import SwiftUI

struct HoleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let hole: THHole
    let fold: Bool
    let listStyle: Bool
    @ObservedObject var preference = Preference.shared
    
    init(hole: THHole, fold: Bool = false, listStyle: Bool = false) {
        self.hole = hole
        self.fold = fold
        self.listStyle = listStyle
    }
    
    var body: some View {
        if fold {
            DisclosureGroup {
                NavigationLink(value: hole) {
                    VStack(alignment: .leading) {
                        holeContent
                    }
                }
                #if os(iOS)
                .previewContextMenu(preview: HoleDetailPage(hole: hole, floors: hole.floors))
                #endif
            } label: {
                tags
            }
        } else {
            NavigationLink(value: hole) {
                VStack(alignment: .leading) {
                    tags
                    holeContent
                }
            }
            #if os(iOS)
            .previewContextMenu(preview: HoleDetailPage(hole: hole, floors: hole.floors))
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
        TagList(hole.tags, lineWrap: false, navigation: !listStyle)
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
                
                Text(hole.lastFloor.content.inlineAttributed())
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

struct HoleView_Previews: PreviewProvider {
    static var previews: some View {
        HoleView(hole: PreviewDecode.decodeObj(name: "hole")!)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
