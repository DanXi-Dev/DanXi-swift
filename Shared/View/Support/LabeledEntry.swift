import SwiftUI

struct LabeledEntry<Content: View>: View {
    let label: LocalizedStringKey
    var showAlert = false
    let content: Content
    
    init(_ label: LocalizedStringKey,
         @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content()
    }
    
    func showAlert(_ showAlert: Bool) -> LabeledEntry {
        var entry = self
        entry.showAlert = showAlert
        return entry
    }
    
    var body: some View {
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
        .listRowBackground(Color.separator.opacity(0.2))
    }
}
