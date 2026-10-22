import SwiftUI

struct MathBlockView: View {
    let expression: MathExpression
    let rendered: RenderedMath?

    var body: some View {
        ScrollView(.horizontal) {
            Group {
                if let rendered {
                    Image(uiImage: rendered.image).renderingMode(.original)
                } else {
                    Text(verbatim: expression.source).font(.callout)
                }
            }
            .padding(.vertical, 3)
        }
        .accessibilityLabel(expression.source)
    }
}
