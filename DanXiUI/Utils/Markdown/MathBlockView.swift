import SwiftUI

struct MathBlockView: View {
    let expression: MathExpression
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @ScaledMetric(relativeTo: .callout) private var fontSize = 16.0
    @State private var rendered: RenderedMath?

    private struct Request: Hashable {
        let expression: MathExpression
        let size: Double
        let scale: CGFloat
        let dark: Bool
    }

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
        .task(id: Request(expression: expression, size: fontSize,
                          scale: displayScale, dark: colorScheme == .dark)) {
            let result = try? await MathRenderer.shared.render(expression, fontSize: fontSize,
                displayScale: displayScale, dark: colorScheme == .dark)
            guard !Task.isCancelled else { return }
            rendered = result
        }
    }
}
