import SwiftUI

struct SpecialTagView: View {
    let content: String

    var body: some View {
        Text(content)
            .foregroundColor(.white)
            .font(.system(size: 10))
            .bold()
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(LinearGradient(gradient: Gradient(colors: [.red, .red.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(4)
            .shadow(radius: 1)
    }
}

#Preview {
    SpecialTagView(content: "Hello, World!")
}
