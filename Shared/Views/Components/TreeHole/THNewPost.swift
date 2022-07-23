import SwiftUI

struct THNewPost: View {
    enum Mode: String, CaseIterable, Identifiable {
        case edit, preview
        var id: Self { self }
    }
    
    @State var content = ""
    @State var tags: [THTag] = []
    @State var mode: Mode = .edit
    
    var body: some View {
        NavigationView {
            VStack {
                navigatorBar
                
                if (mode == .edit) {
                    Form {
                        Section {
                            NavigationLink(destination: THTagSelection(tagList: $tags)) {
                                Label("select_tags", systemImage: "number.square.fill")
                            }
                        }
                        
                        editSection
                    }
                } else {
                    preview
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
    
    private var navigatorBar: some View {
        Picker("Divisions", selection: $mode) {
            Text("edit").tag(Mode.edit)
            Text("preview").tag(Mode.preview)
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var editSection: some View {
        Section {
            if tags.isEmpty {
                Text("no_tags")
                    .foregroundColor(.primary.opacity(0.25))
            } else {
                TagList(tags: tags)
            }
            
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
        } header: {
            Text("th_edit_alert")
        }
        .textCase(nil)
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
