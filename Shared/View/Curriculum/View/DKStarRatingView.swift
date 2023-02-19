import SwiftUI

struct DKStarRatingView: View {
    @Binding var rating: Int
    
    var body: some View {
        HStack(spacing: 2.0) {
            ForEach(0..<5) { index in
                SingleStar(index: index + 1, rating: $rating)
            }
        }
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

struct DKStarRatingView_Previews: PreviewProvider {
    static var previews: some View {
        DKStarRatingView(rating: .constant(3))
    }
}
