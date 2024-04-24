import SwiftUI
import DanXiKit

struct RatingView: View {
    let rank: Rank
    
    var body: some View {
        Grid(alignment: .trailing, verticalSpacing: 0) {
            RatingEntryView(
                rating: rank.overall,
                ratingType: .overall,
                label: "Overall Rating")
            
            RatingEntryView(
                rating: rank.content,
                ratingType: .content,
                label: "Course Content")
            
            RatingEntryView(
                rating: rank.workload,
                ratingType: .workload,
                label: "Course Workload")
            
            RatingEntryView(
                rating: rank.assessment,
                ratingType: .assessment,
                label: "Course Assessment")
        }
    }
}

struct RatingEntryView: View {
    let rating: Double
    let ratingType: RatingType
    let label: LocalizedStringKey
    
    var body: some View {
        GridRow {
            Text(label)
                .foregroundColor(.primary.opacity(0.7))
            ProgressView(value: rating, total: 5.0)
                .frame(width: 100)
            Text(ratingType.text(forRating: rating))
                .foregroundColor(.primary.opacity(0.7))
                .gridColumnAlignment(.leading)
        }
        .font(.caption2)
        .frame(height: 16)
    }
}
