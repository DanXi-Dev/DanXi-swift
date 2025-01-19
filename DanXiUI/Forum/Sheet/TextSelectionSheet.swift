import SwiftUI

struct TextSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let text: String
    
    var body: some View {
        NavigationStack {
            SelectableText(text: text)
                .padding(.horizontal)
                .navigationTitle(String(localized: "Copy Text", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            UIPasteboard.general.string = text
                            dismiss()
                        } label: {
                            Text("Copy All", bundle: .module)
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel", bundle: .module)
                        }
                    }
                }
        }
    }
}

private struct SelectableText: UIViewRepresentable {
    let text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.text = text
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .preferredFont(forTextStyle: .body)
        return textView
    }
    
    func updateUIView(_ view: UITextView, context: Context) {
        view.text = text
    }
}


