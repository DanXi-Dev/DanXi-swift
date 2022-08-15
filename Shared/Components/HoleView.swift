import SwiftUI

struct HoleView: View {
    let hole: THHole
    @ObservedObject var treeholeDataModel = TreeholeDataModel.shared // FIXME: The entire thing is here only because we need to read debugging settings. Maybe there is a better way to achieve the purpose?
    
    var body: some View {
        VStack(alignment: .leading) {
            TagListSimple(tags: hole.tags)
            
            if (treeholeDataModel.nlModelDebuggingMode) {
                // A preview for CoreML Model
                Text(TagPredictor.shared?.debugPredictTagForText(hole.firstFloor.content, modelId: 0) ?? "MaxEntropy NLModel init failed")
                    .foregroundColor(.green)
                Text(TagPredictor.shared?.debugPredictTagForText(hole.firstFloor.content, modelId: 1) ?? "TransferLearning NLModel init failed")
                    .foregroundColor(.red)
            }
            
            if let mdRendered = try? AttributedString(markdown: hole.firstFloor.content.stripToBasicMarkdown()) {
                Text(mdRendered)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                    .transition(.slide)
            } else {
                Text(hole.firstFloor.content.stripToBasicMarkdown())
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                    .transition(.slide)
            }
            HStack {
                info
            }
        }
    }
    
    private var info: some View {
        HStack {
            Text("#\(String(hole.id))")
            Spacer()
            Text(hole.createTime.formatted(date: .abbreviated, time: .shortened))
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
