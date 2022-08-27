import SwiftUI

struct RankView: View {
    let rank: DKRank
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            RankEntryView(
                rating: rank.overall,
                label: "Overall Rating")
            
            RankEntryView(
                rating: rank.content,
                label: "Course Content")
            
            RankEntryView(
                rating: rank.workload,
                label: "Course Workload")
            
            RankEntryView(
                rating: rank.assessment,
                label: "Course Assessment")
        }
    }
}

struct RankEntryView: View {
    let rating: Double
    let label: LocalizedStringKey
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary.opacity(0.7))
            ProgressView(value: rating, total: 5.0)
                .frame(width: 130)
        }
        .font(.caption2)
        .frame(height: 16)
    }
}

struct RankView_Previews: PreviewProvider {
    static var previews: some View {
        RankView(rank: DKRank(overall: 3.0, content: 2.0, workload: 4.0, assessment: 1.0))
    }
}
