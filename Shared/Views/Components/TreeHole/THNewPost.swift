import SwiftUI

struct THNewPost: View {
    enum Mode: String, CaseIterable, Identifiable {
        case edit, preview
        var id: Self { self }
    }
    
    @State var content = ""
    @State var mode: Mode = .edit
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Divisions", selection: $mode.animation()) {
                    Text("edit").tag(Mode.edit)
                    Text("preview").tag(Mode.preview)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if (mode == .edit) {
                    Form {
                        Section {
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
                        
                        Section {
                            NavigationLink(destination: Text("tags")) {
                                Label("select_tags", systemImage: "number.square.fill")
                            }
                        }
                    }
                } else {
                    Form {
                        Text(content)
                    }
                }
            }
            .navigationTitle("new_post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("send", action: {})
                }
            }
        }
    }
}

struct THNewPost_Previews: PreviewProvider {
    static var previews: some View {
        THNewPost()
    }
}
