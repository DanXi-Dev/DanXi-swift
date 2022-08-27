import SwiftUI

struct StarsView: View {
    var rating: CGFloat
    var maxRating: Int = 5

    var body: some View {
        let stars = HStack(spacing: 0) {
            ForEach(0..<maxRating, id: \.self) { _ in
                Image(systemName: "star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }

        stars.overlay(
            GeometryReader { g in
                let width = rating / CGFloat(maxRating) * g.size.width
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: width)
                        
                }
            }
                .mask(stars.symbolVariant(.fill))
        )
        .foregroundColor(.orange)
    }
}

struct StarsView_Previews: PreviewProvider {
    static var previews: some View {
        StarsView(rating: 3.4)
            .frame(width: 70)
    }
}
