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
            .background(LinearGradient(gradient: Gradient(colors: [Color("danxi pink light"), Color("danxi pink")]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(4)
            .shadow(radius: 1)
    }
}
