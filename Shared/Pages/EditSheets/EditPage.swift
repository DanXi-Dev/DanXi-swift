import SwiftUI

struct EditPage: View {
    let divisionId: Int
    @State var content = ""
    @State var tags: [THTag] = []
    @State var previewMode = false
    @State var loading = false
    
    @Environment(\.dismiss) private var dismiss
    
    func sendPost() {
        Task {
            // TODO: pre post check (e.g.: empty tags)
            
            loading = true
            defer { loading = false }
            
            do {
                try await NetworkRequests.shared.newPost(
                    content: content,
                    divisionId: divisionId,
                    tags: tags)
                dismiss()
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
                            Label("Select Tags", systemImage: "tag")
                        }
                    }
                    suggestedTags
                    editSection
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: {
                        dismiss()
                    })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: sendPost) {
                        Text("Send")
                            .bold()
                    }
                    .disabled(loading)
                }
            }
        }
    }
    
    @ViewBuilder
    private var suggestedTags: some View {
        if let predictor = TagPredictor.shared {
            Section("Suggested Tags") {
                if (content.count >= 5) {
                    // TODO: Add a slight delay to prevent prediction at every type
                    // TODO: Add animation
                    // FIXME: Can't select individual tag
                    HStack {
                        ForEach(predictor.suggest(content), id: \.self) { prediction in
                            Button(action: {tags.append(THTag(id: 0, temperature: 0, name: prediction))}) {
                                Text(prediction)
                                    .tagStyle(color: randomColor(name: prediction))
                            }
                        }
                    }
                } else {
                    Text("Type more to get suggestions...")
                }
            }
        } else {
            // TODO: Handle CoreML init failure
            Text("Failed to initialize CoreML")
                .foregroundColor(.red)
        }
    }
    
    private var editSection: some View {
        Section {
            if tags.isEmpty {
                Text("No tags")
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
            Text("TH Edit Alert")
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
                Text("Enter post content")
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
    @ObservedObject var model = TreeholeDataModel.shared
    
    @Binding var tagList: [THTag]
    @State var searchText = ""
    
    var body: some View {
        List {
            if tagList.isEmpty {
                Text("No tags")
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
        .navigationTitle("Select Tags")
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
        EditPage(divisionId: 1)
    }
}
