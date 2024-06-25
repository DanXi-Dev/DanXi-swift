import SwiftUI
import DanXiKit

struct RatingView: View {
    let rank: Rank
    
    var body: some View {
        Grid(alignment: .trailing, verticalSpacing: 0) {
            RatingEntryView(
                rating: rank.overall,
                ratingType: .overall,
                label: String(localized: "Overall Rating", bundle: .module))
            
            RatingEntryView(
                rating: rank.content,
                ratingType: .content,
                label: String(localized: "Course Content", bundle: .module))
            
            RatingEntryView(
                rating: rank.workload,
                ratingType: .workload,
                label: String(localized: "Course Workload", bundle: .module))
            
            RatingEntryView(
                rating: rank.assessment,
                ratingType: .assessment,
                label: String(localized: "Course Assessment", bundle: .module))
        }
    }
}

struct RatingEntryView: View {
    let rating: Double
    let ratingType: RatingType
    let label: String
    
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
