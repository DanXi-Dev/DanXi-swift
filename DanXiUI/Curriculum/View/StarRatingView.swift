import SwiftUI

enum RatingType {
    case overall, content, workload, assessment
    
    func text(forRating rating: Int) -> LocalizedStringKey {
        guard rating >= 1 && rating <= 5 else {
            return ""
        }
        switch self {
        case .overall:
            return ["Very Poor", "Poor", "Average", "Good", "Excellent"][rating-1]
        case .content:
            return ["Hardcore", "Challenging", "Average", "Easy", "Very Easy"][rating-1]
        case .workload:
            return ["Very High", "High", "Average", "Low", "Very Low"][rating-1]
        case .assessment:
            return ["Very Strict", "Strict", "Average", "Lenient", "Very Lenient"][rating-1]
        }
    }
    
    func text(forRating rating: Double) -> LocalizedStringKey {
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
