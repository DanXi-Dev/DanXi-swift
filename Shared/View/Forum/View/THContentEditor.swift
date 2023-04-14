import SwiftUI

struct THContentEditor: View {
    @Binding var content: String
    
    var body: some View {
        Group {
            Section {
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Enter post content")
                            .foregroundColor(.primary.opacity(0.25))
                            .padding(.top, 7)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $content)
                        .frame(height: 250)
                }
            } header: {
                Text("TH Edit Alert")
            }
            
            if !content.isEmpty {
                Section {
                    THFloorContent(content, interactable: false)
                } header: {
                    Text("Preview")
                }
            }
        }
    }
}
