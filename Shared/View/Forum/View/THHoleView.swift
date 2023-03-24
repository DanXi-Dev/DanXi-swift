import SwiftUI

struct THHoleView: View {
    @Environment(\.colorScheme) var colorScheme

    let hole: THHole
    let fold: Bool
    @ObservedObject var preference = Preference.shared
    
    init(hole: THHole, fold: Bool = false) {
        self.hole = hole
        self.fold = fold
    }
    
    var body: some View {
        if fold {
            DisclosureGroup {
                NavigationPlainLink(value: hole) {
                    VStack(alignment: .leading) {
                        holeContent
                    }
                }
            } label: {
                tags
            }
        } else {
            NavigationPlainLink(value: hole) {
                VStack(alignment: .leading) {
                    tags
                    holeContent
                }
            }
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
                    THSpecialTagView(content: hole.firstFloor.spetialTag)
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
        ScrollView(.horizontal) {
            HStack {
                ForEach(hole.tags) { tag in
                    THTagView(tag)
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

struct THHoleView_Previews: PreviewProvider {
    static var previews: some View {
        THHoleView(hole: Bundle.main.decodeData("hole")!)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
