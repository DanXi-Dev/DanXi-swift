import SwiftUI
import Introspect

struct TextSelectionView: View {
    let text: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            TextEditor(text: .constant(text))
                .introspectTextView { textField in
                    textField.isEditable = false
                }
                .padding(.horizontal)
                .navigationTitle("Select Text")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .status) {
                        Button {
                            UIPasteboard.general.string = text
                            dismiss()
                        } label: {
                            Label {
                                Text("Copy Full Text")
                                    .bold()
                            } icon: {
                                Image(systemName: "doc.on.doc")
                            }
                            .labelStyle(.titleAndIcon)
                        }
                    }
                }
        }
    }
}

struct TextSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TextSelectionView(text: "Hello World!")
    }
}
