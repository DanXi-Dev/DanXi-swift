import SwiftUI

struct THNewPost: View {
    @EnvironmentObject var dataModel: THDataModel
    @Binding var showNewPostPage: Bool
    @State var content = ""
    @State var tags: [THTag] = []
    @State var previewMode = false
    
    func sendPost() {
        guard let token = dataModel.token else {
            return
        }
        
        Task {
            // TODO: pre post check (e.g.: empty tags)
            
            do {
                try await THsendNewPost(
                    token: token,
                    content: content,
                    divisionId: dataModel.currentDivision.id,
                    tags: tags)
                showNewPostPage = false
            } catch {
                // TODO: alert user
                print("DANXI-DEBUG: post failed")
            }
        }
    }
    
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel", action: {
                        showNewPostPage = false
                    })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("send", action: sendPost)
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
    static let dataModel = THDataModel()
    
    static var previews: some View {
        THNewPost(showNewPostPage: .constant(true))
            .environmentObject(dataModel)
    }
}
