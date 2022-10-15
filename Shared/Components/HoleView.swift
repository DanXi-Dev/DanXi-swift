import SwiftUI

struct HoleView: View {
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
                VStack(alignment: .leading) {
                    holeContent
                }
                .backgroundLink { HoleDetailPage(hole: hole) }
                #if os(iOS)
                // FIXME: will cause "NavigationLink presenting a value must appear inside a NavigationContent-based NavigationView. Link will be disabled.", consider update preview code.
                .previewContextMenu(preview: HoleDetailPage(hole: hole, floors: hole.floors))
                #endif
                .listRowSeparator(.hidden, edges: .top)
                .listRowInsets(.init(top: 0,
                                     leading: -1,
                                     bottom: 5,
                                     trailing: 15))
            } label: {
                tags
            }
        } else {
            VStack(alignment: .leading) {
                tags
                holeContent
            }
            .backgroundLink { HoleDetailPage(hole: hole) }
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
                .font(.system(size: 16))
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

    private var tags: some View {
        TagList(hole.tags)
    }
}

struct HoleView_Previews: PreviewProvider {
    static var previews: some View {
        HoleView(hole: PreviewDecode.decodeObj(name: "hole")!)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
