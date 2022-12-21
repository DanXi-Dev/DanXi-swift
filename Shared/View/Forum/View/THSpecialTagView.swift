import SwiftUI

/// View that renders a special tag of a floor.
struct THSpecialTagView: View {
    let content: String
    
    var body: some View {
        Text(content)
            .foregroundColor(.white)
            .font(.caption2)
            .fontWeight(.black)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(LinearGradient(gradient: Gradient(colors: [Color("pink-light"), Color("pink")]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(4)
            .shadow(radius: 1)
    }
}

struct THSpecialTagView_Previews: PreviewProvider {
    static var previews: some View {
        THSpecialTagView(content: "Special Tag")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
