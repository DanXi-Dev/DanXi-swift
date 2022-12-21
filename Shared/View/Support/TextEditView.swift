import SwiftUI

struct TextEditView: View {
    @Binding var content: String
    @FocusState var editorActive: Bool
    let placeholder: LocalizedStringKey
    let height: CGFloat
    
    
    init(_ content: Binding<String>,
         placeholder: LocalizedStringKey = "",
         height: CGFloat = 250) {
        self._content = content
        self.placeholder = placeholder
        self.height = height
    }
    
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty {
                Text(placeholder)
                    .foregroundColor(.primary.opacity(0.25))
                    .padding(.top, 7)
                    .padding(.leading, 4)
            }
            
            TextEditor(text: $content)
                .focused($editorActive)
                .frame(height: height)
        }
        .toolbar {
            // hide the keyboard
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button {
                    editorActive = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
    }
}

struct TextEditView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            TextEditView(.constant(""),
                         placeholder: "Enter reply content")
        }
    }
}
