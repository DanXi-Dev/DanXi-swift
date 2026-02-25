import SwiftUI
import DanXiKit
import ViewUtils

struct AISummarySheet: View {
    @ObservedObject var holeModel: HoleModel
    @StateObject private var model: AISummaryModel
    
    init(holeModel: HoleModel) {
        self.holeModel = holeModel
        self._model = StateObject(wrappedValue: AISummaryModel(hole: holeModel.hole))
    }
    
    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(Text("AI Summary", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            holeModel.showAISummarySheet = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
        }
        .environmentObject(holeModel)
        .presentationDetents([.medium, .large])
        .task {
            await model.loadSummary()
        }
        .onReceive(holeModel.scrollControl) { _ in
            holeModel.showAISummarySheet = false
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            loadingView
        case .loaded(let summaryContent):
            loadedView(content: summaryContent)
        case .error(let error):
            errorView(error: error)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating AI Summary for \(holeModel.floors.count) floors...", bundle: .module)
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private func loadedView(content: AISummaryContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let keywords = content.keywords{
                    KeywordsView(keywords: keywords)
                    Divider()
                }
                
                
                SummaryView(summary: content.summary)
                
                Divider()
                
                if let branches = content.branches{
                    BranchesView(branches: branches, holeModel: holeModel)
                    Divider()
                }
                
                if let interactions = content.interactions{
                    InteractionsView(interactions: interactions, holeModel: holeModel)
                }
            }
            .padding()
        }
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Failed to generate summary", bundle: .module)
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                Task {
                    await model.loadSummary()
                }
            } label: {
                Text("Retry", bundle: .module)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

}

private struct KeywordsView: View {
    let keywords: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Keywords", bundle: .module), systemImage: "tag.fill")
                .font(.headline)
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            WrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(keywords, id: \.self) { keyword in
                    TagView(keyword)
                }
            }
        }
    }
}

private struct SummaryView: View {
    let summary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Summary", bundle: .module), systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(summary)
                .font(.body)
        }
    }
}

private struct BranchesView: View {
    let branches: [AISummaryContent.Branch]
    @ObservedObject var holeModel: HoleModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Branches", bundle: .module), systemImage: "arrow.triangle.branch")
                .font(.headline)
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(branches, id: \.self) { branch in
                    BranchRow(branch: branch, holeModel: holeModel)
                }
            }
        }
    }
}

private struct BranchRow: View {
    let branch: AISummaryContent.Branch
    @ObservedObject var holeModel: HoleModel
    
    var body: some View {
        DisclosureGroup {
            Divider()
            
            Text(branch.content)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            ForEach(branch.representativeFloors, id: \.self) { floorId in
                if let floor = holeModel.getFloor(floorId: floorId) {
                    LocalMentionView(floor)
                } else {
                    Text("Floor ##\(String(floorId)) not found", bundle: .module)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding([.top, .bottom], 10)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: branch.color))
                    .frame(width: 8, height: 8)
                
                Text(branch.label)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: branch.color),
                            Color(hex: branch.color).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

private struct InteractionsView: View {
    let interactions: [AISummaryContent.Interaction]
    @ObservedObject var holeModel: HoleModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Interactions", bundle: .module), systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            ForEach(interactions, id: \.self) { interaction in
                InteractionRow(interaction: interaction, holeModel: holeModel)
            }
        }
    }
}

private struct InteractionRow: View {
    let interaction: AISummaryContent.Interaction
    @ObservedObject var holeModel: HoleModel
    
    var body: some View {
        DisclosureGroup {
            Divider()
            if let toFloor = holeModel.getFloor(floorId:interaction.toFloor) {
                LocalMentionView(toFloor)
            } else {
                Text("Floor ##\(String(interaction.toFloor)) not found", bundle: .module)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding([.top, .bottom], 10)
            }
            if let fromFloor = holeModel.getFloor(floorId: interaction.fromFloor) {
                LocalMentionView(fromFloor)
            } else {
                Text("Floor ##\(String(interaction.fromFloor)) not found", bundle: .module)                        .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding([.top, .bottom], 10)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: interaction.interactionType.systemImage)
                    .foregroundStyle(interaction.interactionType.color)
                    .font(.body)
                    .frame(width: 20)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(interaction.fromUser)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                        
                        Text(interaction.toUser)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                    }
                    .font(.subheadline)
                    
                    Text(interaction.content)
                        .font(.callout)
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
        .background(.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            interaction.interactionType.color,
                            interaction.interactionType.color.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

extension AISummaryContent.Interaction.InteractionType {
    var systemImage: String {
        switch self {
        case .support: return "hand.thumbsup.fill"
        case .question: return "questionmark.circle.fill"
        case .reply: return "arrowshape.turn.up.left.fill"
        case .rebuttal: return "hand.thumbsdown.fill"
        case .supplement: return "pencil.and.outline"
        }
    }

    var color: Color {
        switch self {
        case .support: return .green
        case .question: return .purple
        case .reply: return .blue
        case .rebuttal: return .red
        case .supplement: return .indigo
        }
    }
}
