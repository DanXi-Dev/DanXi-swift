import SwiftUI

struct THPosterView: View {
    let name: String
    let isPoster: Bool
    @Environment(\.displayScale) var displayScale
    
    var body: some View {
        HStack {
            if isPoster {
                Text(verbatim: "DZ")
                    .font(.footnote)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6.0)
                    .background(randomColor(name))
                    .cornerRadius(3.0)
            }
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .foregroundColor(randomColor(name))
        .padding(.leading, 10)
        .overlay(
            Rectangle()
                .frame(width: 3, height: nil, alignment: .leading)
                .foregroundColor(randomColor(name))
                .padding(.vertical, 1), alignment: .leading)
    }
}


struct THPosterView_Previews: PreviewProvider {
    static var previews: some View {
        THPosterView(name: "Tom", isPoster: true)
    }
}
