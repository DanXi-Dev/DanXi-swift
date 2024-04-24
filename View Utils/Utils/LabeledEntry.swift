import SwiftUI

public struct LabeledEntry<Content: View>: View {
    private let label: LocalizedStringKey
    private var showAlert = false
    private let content: Content
    
    public init(_ label: LocalizedStringKey,
         @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content()
    }
    
    public func showAlert(_ showAlert: Bool) -> LabeledEntry {
        var entry = self
        entry.showAlert = showAlert
        return entry
    }
    
    public var body: some View {
        LabeledContent {
            HStack {
                content
                if showAlert {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                }
            }
        } label: {
            HStack {
                Text(label)
                    .bold()
                Spacer()
            }
            .frame(maxWidth: 90)
        }
        .listRowBackground(Color(.separator).opacity(0.2))
    }
}
