import SwiftUI

struct EditPage: View {
    let divisionId: Int
    @Binding var showNewPostPage: Bool
    @State var content = ""
    @State var tags: [THTag] = []
    @State var previewMode = false
    
    func sendPost() {
        Task {
            // TODO: pre post check (e.g.: empty tags)
            
            do {
                try await networks.newPost(
                    content: content,
                    divisionId: divisionId,
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

struct THTagSelection: View {
    @ObservedObject var model = treeholeDataModel
    
    @Binding var tagList: [THTag]
    @State var searchText = ""
    
    var body: some View {
        List {
            if tagList.isEmpty {
                Text("no_tags")
                    .foregroundColor(.primary.opacity(0.25))
            } else {
                TagList(tags: tagList)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
            
            ForEach(searchResults) { result in
                Button(action: { tagList.append(result) }) {
                    TagRowView(tag: result)
                }
            }
        }
        .navigationTitle("select_tags")
    }
    
    var searchResults: [THTag] {
        if searchText.isEmpty {
            return model.tags
        } else {
            // TODO: filter tags that already exists
            return model.tags.filter { $0.name.contains(searchText) }
        }
    }
}

struct THNewPost_Previews: PreviewProvider {
    static var previews: some View {
        EditPage(divisionId: 1, showNewPostPage: .constant(true))
    }
}
