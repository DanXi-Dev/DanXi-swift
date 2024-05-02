import SwiftUI

public struct FoldedView<Label: View, Content: View>: View {
    @State private var expand: Bool
    private let label: Label
    private let content: Content
    
    public init(expand: Bool = false,
                @ViewBuilder label: () -> Label,
                @ViewBuilder content: () -> Content) {
        self._expand = State(initialValue: expand)
        self.label = label()
        self.content = content()
    }
    
    public var body: some View {
        if expand {
            content
        } else {
            Section { // We must wrap the section outside the button to fix #2 of #133
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
