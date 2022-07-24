import SwiftUI

struct THNewPost: View {
    @State var content = ""
    @State var tags: [THTag] = []
    @State var previewMode = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        NavigationLink(destination: THTagSelection(tagList: $tags)) {
                            Label("select_tags", systemImage: "tag")
                        }
                    }
                    
                    editSection
                }
            }
            .navigationTitle("new_post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("send", action: {
                        // TODO: upload post
                    })
                }
            }
        }
    }

    private var editSection: some View {
        Section {
            if tags.isEmpty {
                Text("no_tags")
                    .foregroundColor(.primary.opacity(0.25))
            } else {
                TagList(tags: tags)
            }
            
            if previewMode {
                Text(content)
            } else {
                editor
            }
        } header: {
            Text("th_edit_alert")
        } footer: {
            HStack {
                // TODO: toolbar (bold, italics, ...)
                
                Spacer()
                Button(action: { previewMode.toggle() }) {
                    Image(systemName: previewMode ? "eye.fill" : "eye")
                }
            }
        }
        .textCase(nil)
    }
    
    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty {
                Text("th_edit_prompt")
                    .foregroundColor(.primary.opacity(0.25))
                    .padding(.top, 7)
                    .padding(.leading, 4)
            }
            TextEditor(text: $content)
                .frame(height: 250)
        }
    }
    
    private var preview: some View {
        List {
            Section {
                Text(content)
            } header: {
                TagList(tags: tags)
            }
            .textCase(nil)
        }
        .listStyle(.grouped)
    }
}

struct THNewPost_Previews: PreviewProvider {
    static var previews: some View {
        THNewPost()
    }
}
