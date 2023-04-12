import SwiftUI

struct THPosterView: View {
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
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, posterPadding)
                    .background(randomColor(name))
                    .cornerRadius(corner)
            }
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.bold)
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


struct THPosterView_Previews: PreviewProvider {
    static var previews: some View {
        THPosterView(name: "Tom", isPoster: true)
    }
}
