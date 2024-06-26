import SwiftUI

enum RatingType {
    case overall, content, workload, assessment
    
    static let overallList = [
        String(localized: "Very Poor", bundle: .module),
        String(localized: "Poor", bundle: .module),
        String(localized: "Average", bundle: .module),
        String(localized: "Good", bundle: .module),
        String(localized: "Excellent", bundle: .module)
    ]
    
    static let contentList = [
        String(localized: "Hardcore", bundle: .module),
        String(localized: "Challenging", bundle: .module),
        String(localized: "Average", bundle: .module),
        String(localized: "Easy", bundle: .module),
        String(localized: "Very Easy", bundle: .module)
    ]

    static let workloadList = [
        String(localized: "Very High", bundle: .module),
        String(localized: "High", bundle: .module),
        String(localized: "Average", bundle: .module),
        String(localized: "Low", bundle: .module),
        String(localized: "Very Low", bundle: .module)
    ]

    static let assessmentList = [
        String(localized: "Very Strict", bundle: .module),
        String(localized: "Strict", bundle: .module),
        String(localized: "Average", bundle: .module),
        String(localized: "Lenient", bundle: .module),
        String(localized: "Very Lenient", bundle: .module)
    ]
    
    func text(forRating rating: Int) -> String {
        guard rating >= 1 && rating <= 5 else {
            return ""
        }
        switch self {
        case .overall:
            return RatingType.overallList[rating-1]
        case .content:
            return RatingType.contentList[rating-1]
        case .workload:
            return RatingType.workloadList[rating-1]
        case .assessment:
            return RatingType.assessmentList[rating-1]
        }
    }
    
    func text(forRating rating: Double) -> String {
        let rounded = Int(rating.rounded(.toNearestOrAwayFromZero))
        return text(forRating: rounded)
    }
}

struct StarRatingView: View {
    @Binding var rating: Int
    var ratingType: RatingType
    
    var body: some View {
        HStack(spacing: 2.0) {
            ratingText(rating)
            ForEach(0..<5) { index in
                SingleStar(index: index + 1, rating: $rating)
            }
        }
    }
    
    private func ratingText(_ rating: Int) -> some View {
        Text(ratingType.text(forRating: rating))
            .foregroundColor(.gray)
            .font(.caption)
            .fixedSize()
    }
}

fileprivate struct SingleStar: View {
    let index: Int
    @Binding var rating: Int
    
    var body: some View {
        Button {
            rating = index
        } label: {
            Image(systemName: "star")
                .symbolVariant(rating >= index ? .fill : .none)
        }
        .buttonStyle(.plain)
        .foregroundColor(.accentColor)
    }
}
