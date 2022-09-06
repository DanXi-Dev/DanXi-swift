import SwiftUI

struct EditPage: View {
    let divisionId: Int
    @State var content = ""
    @State var tags: [THTag] = []
    @State var loading = false
    
    @Environment(\.dismiss) private var dismiss
    @State var showTagsSelection = false
    @State var searchTagText = ""
    
    @State var showError = false
    @State var errorInfo = ErrorInfo()
    
    var filteredTags: [THTag] {
        // filter tag that already selected
        let tags = TreeholeDataModel.shared.tags.filter { tag in
            !self.tags.contains(tag)
        }

        if searchTagText.isEmpty {
            return tags
        } else {
            return tags.filter { tag in
                tag.name.contains(searchTagText)
            }
        }
    }
    
    func sendPost() {
        Task {
            loading = true
            defer { loading = false }
            
            do {
                try await NetworkRequests.shared.newPost(
                    content: content,
                    divisionId: divisionId,
                    tags: tags)
                dismiss()
            } catch let error as NetworkError {
                errorInfo = error.localizedErrorDescription
                showError = true
            } catch {
                errorInfo = ErrorInfo(title: "Unknown Error",
                                      description: "Error description: \(error.localizedDescription)")
                showError = true
            }
        }
    }
    

    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    tagsSection
                    
                    Section {
                        TextEditView($content,
                                     placeholder: "Enter post content")
                    } header: {
                        Text("TH Edit Alert")
                    }
                    .textCase(nil)
                    
                    if !content.isEmpty {
                        Section {
                            ReferenceView(content)
                                .padding(.vertical, 5)
                        } header: {
                            Text("Preview")
                        }
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: sendPost) {
                        Text("Send")
                            .bold()
                    }
                    .disabled(loading || tags.isEmpty || content.isEmpty)
                }
            }
            .alert("Send Post Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorInfo.description)
            }
            .sheet(isPresented: $showTagsSelection) {
                NavigationView {
                    List {
                        ForEach(filteredTags) { tag in
                            HStack {
                                Text(tag.name)
                                    .tagStyle(color: randomColor(name: tag.name))
                                
                                Spacer()
                                
                                Button {
                                    tags.append(tag)
                                    showTagsSelection = false
                                } label: {
                                    Label(String(tag.temperature), systemImage: "flame")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .navigationTitle("Select Tags")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $searchTagText, placement: .navigationBarDrawer(displayMode: .always))
                }
            }
            .overlay(
                HStack(alignment: .center, spacing: 20) {
                    ProgressView()
                    Text("Sending Post...")
                        .foregroundColor(.secondary)
                        .bold()
                }
                    .padding(35)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .animation(.easeInOut, value: loading)
                    .opacity(loading ? 1 : 0)
            )
            .ignoresSafeArea(.keyboard) // prevent keyboard from pushing up loading overlay
        }
    }
    
    private var tagsSection: some View {
        Section {
            if tags.isEmpty {
                Text("No tags")
                    .foregroundColor(.primary.opacity(0.25))
            } else {
                FlexibleView(data: tags, spacing: 15, alignment: .leading) { tag in
                    Text(tag.name)
                        .tagStyle(color: randomColor(name: tag.name), fontSize: 16)
                        .overlay(alignment: .topTrailing) {
                            Button { // remove this tag
                                tags.removeAll { value in
                                    value.id == tag.id
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 11))
                                    .frame(width: 17, height: 17)
                                    .foregroundColor(.secondary)
                                    .background(.regularMaterial)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                            .buttonStyle(.borderless)
                            .transition(.opacity)
                        }
                }
                .padding(.vertical, 5)
            }
        } header: {
            Button {
                showTagsSelection = true
            } label: {
                Label("Add Tag", systemImage: "tag")
            }
            .disabled(tags.count >= 5) // can't add more than 5 tags
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
}

struct THNewPost_Previews: PreviewProvider {
    static var previews: some View {
        EditPage(divisionId: 1)
    }
}
