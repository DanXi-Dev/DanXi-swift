import SwiftUI

struct FoldedView<Label: View, Content: View>: View {
    @State private var expand: Bool
    private let label: Label
    private let content: Content

    init(expand: Bool = false,
         @ViewBuilder label: () -> Label,
         @ViewBuilder content: () -> Content)
    {
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
                    HStack(alignment: .center) {
                        Spacer()
                        Text("Folded")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .fontWeight(.light)
                            .padding(.leading, 3)
                            .padding(.top, 1)
                            .fixedSize()
                    }
                    .background(alignment: .leading) {
                        HStack {
                            label
                                .fixedSize()
                        }
                        .clipped()
                    }
                }
            }
        }
    }
}
