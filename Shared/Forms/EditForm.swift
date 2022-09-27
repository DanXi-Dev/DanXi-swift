import SwiftUI

struct EditForm: View {
    @State var divisionId: Int
    @AppStorage("post-draft") var content = ""
    @State var tags: [String] = []
    
    var body: some View {
        FormPrimitive(title: "New Post",
                      allowSubmit: !tags.isEmpty && !content.isEmpty,
                      errorTitle: "Send Post Failed") {
            Section {
                Picker(selection: $divisionId, label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(TreeholeDataModel.shared.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            TagField(tags: $tags, max: 5)
            
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
        } action: {
            try await DXNetworks.shared.createHole(
                content: content,
                divisionId: divisionId,
                tags: tags)
            content = ""
        }
    }
}

struct EditForm_Previews: PreviewProvider {
    static var previews: some View {
        EditForm(divisionId: 1)
    }
}
