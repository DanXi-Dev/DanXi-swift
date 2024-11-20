import SwiftUI
import ViewUtils

struct PosterView: View {
    let name: String
    let isPoster: Bool
    
    @ScaledMetric var barWidth = 3.0
    @ScaledMetric var corner = 3.0
    @ScaledMetric var posterPadding = 6.0
    @ScaledMetric var barPadding = 10.0
    
    var body: some View {
        HStack {
            if isPoster {
                Text(verbatim: "DZ")
                    .font(.footnote)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, posterPadding)
                    .background(randomColor(name))
                    .cornerRadius(corner)
            }
            
            Text(name)
                .font(.subheadline)
                .bold()
        }
        .foregroundColor(randomColor(name))
        .padding(.leading, barPadding)
        .overlay(
            Rectangle()
                .frame(width: barWidth, height: nil, alignment: .leading)
                .foregroundColor(randomColor(name))
                .padding(.vertical, 1), alignment: .leading)
    }
}
