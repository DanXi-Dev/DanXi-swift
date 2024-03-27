import SwiftUI

struct FoldedView<Label: View, Content: View>: View {
    @State private var expand: Bool
    private let label: Label
    private let content: Content

    init(expand: Bool = false,
         @ViewBuilder label: () -> Label,
         @ViewBuilder content: () -> Content) {
        self._expand = State(initialValue: expand)
        self.label = label()
        self.content = content()
    }

    var body: some View {
        Group {
            if expand {
                content
            } else {
                Button {
                    withAnimation {
                        expand = true
                    }
                } label: {
                    label
                }
            }
        }
    }
}
