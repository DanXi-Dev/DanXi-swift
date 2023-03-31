import SwiftUI
import WrappingHStack

/// Present a section to select some tags.
struct THTagField: View {
    @Binding var tags: [String]
    let max: Int?
    
    @State var searchText = ""
    @State var showTagSelection = false
    
    @MainActor
    var filteredTags: [THTag] {
        let tags = DXModel.shared.tags.filter { tag in
            !self.tags.contains(tag.name)
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
    
    init(tags: Binding<[String]>, max: Int? = nil) {
        self._tags = tags
        self.max = max
    }
    
    var body: some View {
        Section {
            if tags.isEmpty {
                Text("No tags")
                    .foregroundColor(.primary.opacity(0.25))
            } else {
                WrappingHStack(alignment: .leading) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .tagStyle(color: randomColor(tag), font: .system(size: 16))
                            .overlay(alignment: .topTrailing) {
                                // remove this tag
                                Button {
                                    tags.removeAll { $0 == tag }
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
    
    @MainActor
    private var tagSelection: some View {
        NavigationView {
            List {
                ForEach(filteredTags) { tag in
                    Button {
                        showTagSelection = false
                        tags.append(tag.name)
                    } label: {
                        HStack {
                            Text(tag.name)
                                .tagStyle(color: randomColor(tag.name))
                            Spacer()
                            
                            // FIXME: SwiftUI bug when using Label
                            Group {
                                Image(systemName: "flame")
                                Text(String(tag.temperature))
                            }
                            .foregroundColor(.red)
                            .font(.system(size: 15))
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
