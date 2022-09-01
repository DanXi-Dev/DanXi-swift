import SwiftUI

struct SpecialTagView: View {
    let content: String
    
    var body: some View {
        Text(content)
            .foregroundColor(.white)
            .font(.caption2)
            .fontWeight(.black)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.7), Color.pink]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(4)
            .shadow(radius: 1)
    }
}

struct SpecialTagView_Previews: PreviewProvider {
    static var previews: some View {
        SpecialTagView(content: "测试")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
