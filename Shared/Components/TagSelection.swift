import SwiftUI

struct TagField: View {
    @Binding var tags: [THTag]
    @State var showTagSelection = false
    let max: Int?
    @State var searchText = ""
    
    var filteredTags: [THTag] {
        let tags = TreeholeDataModel.shared.tags.filter { tag in
            !self.tags.contains(tag)
        }
        
        if searchText.isEmpty {
            return tags
        } else {
            return tags.filter { tag in
                tag.name.contains(searchText)
            }
        }
    }
    
    var canAdd: Bool {
        if let max = max {
            return tags.count < max
        }
        return true
    }
    
    init(tags: Binding<[THTag]>, max: Int? = nil) {
        self._tags = tags
        self.max = max
    }
    
    var body: some View {
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
                showTagSelection = true
            } label: {
                Label("Add Tag", systemImage: "tag")
            }
            .disabled(!canAdd) // can't add more than `max` tags
        }
        .sheet(isPresented: $showTagSelection) {
            tagSelection
        }
    }
    
    private var tagSelection: some View {
        NavigationView {
            List {
                ForEach(filteredTags) { tag in
                    HStack {
                        Text(tag.name)
                            .tagStyle(color: randomColor(name: tag.name))
                        
                        Spacer()
                        
                        Button {
                            showTagSelection = false
                            tags.append(tag)
                        } label: {
                            Label(String(tag.temperature), systemImage: "flame")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}