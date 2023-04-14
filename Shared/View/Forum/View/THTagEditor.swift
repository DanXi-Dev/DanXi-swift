import SwiftUI
import WrappingHStack

struct THTagEditor: View {
    let maxSize: Int?
    @Binding var tags: [String]
    @State var text = ""
    @ScaledMetric var width = 100
    
    init(_ tags: Binding<[String]>, maxSize: Int? = nil) {
        self._tags = tags
        self.maxSize = maxSize
    }
    
    func appendTag(_ newTag: String) {
        if text.isEmpty { return }
        
        text = ""
        if !tags.contains(newTag) {
            withAnimation {
                self.tags.append(newTag)
            }
        }
    }
    
    func removeTag(_ tag: String) {
        withAnimation {
            tags.removeAll { $0 == tag }
        }
    }
    
    var suggestedTags: [THTag] {
        if text.isEmpty { return [] }
        
        var tags = DXModel.shared.tags.filter { tag in
            !self.tags.contains(tag.name) && tag.name.contains(text)
        }
        if tags.count > 5 {
            tags = Array(tags[0..<5])
        }
        return tags
    }
    
    var allowAppend: Bool {
        guard let maxSize = maxSize else { return true }
        return tags.count < maxSize
    }
    
    var body: some View {
        Group {
            WrappingHStack(alignment: .leading) {
                ForEach(tags, id: \.self) { tag in
                    THTagView(tag)
                        .transition(.scale)
                        .onTapGesture {
                            removeTag(tag)
                        }
                }
                
                if allowAppend {
                    TextField("Add Tag", text: $text)
                        .submitLabel(.done)
                        .onSubmit {
                            appendTag(text)
                        }
                        .frame(width: width)
                }
            }
            
            ForEach(suggestedTags) { tag in
                Button {
                    appendTag(tag.name)
                } label: {
                    HStack {
                        Label(tag.name, systemImage: "tag")
                            .foregroundColor(randomColor(tag.name))
                        Label(String(tag.temperature), systemImage: "flame")
                            .font(.footnote)
                            .foregroundColor(.separator)
                    }
                }
            }
        }
    }
}
