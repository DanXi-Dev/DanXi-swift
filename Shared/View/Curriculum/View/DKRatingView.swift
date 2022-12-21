import SwiftUI

struct DKRatingView: View {
    let rank: DKRank
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            DKRatingEntryView(
                rating: rank.overall,
                label: "Overall Rating")
            
            DKRatingEntryView(
                rating: rank.content,
                label: "Course Content")
            
            DKRatingEntryView(
                rating: rank.workload,
                label: "Course Workload")
            
            DKRatingEntryView(
                rating: rank.assessment,
                label: "Course Assessment")
        }
    }
}

struct DKRatingEntryView: View {
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

struct DKRatingView_Previews: PreviewProvider {
    static var previews: some View {
        DKRatingView(rank: DKRank(overall: 3.0, content: 2.0, workload: 4.0, assessment: 1.0))
    }
}
