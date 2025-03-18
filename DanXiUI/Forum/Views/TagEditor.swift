import SwiftUI
import ViewUtils
import DanXiKit

struct TagEditor: View {
    @ObservedObject private var tagStore = TagStore.shared
    
    private let maxSize: Int?
    @Binding private var tags: [String]
    @State private var text = ""
    @ScaledMetric private var textFieldWidth = 100
    
    init(_ tags: Binding<[String]>, maxSize: Int? = nil) {
        self._tags = tags
        self.maxSize = maxSize
    }
    
    func appendTag(_ newTag: String) {
        if text.isEmpty { return }
        
        text = ""
        if !tags.contains(newTag) {
            self.tags.append(newTag)
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    var suggestedTags: [Tag] {
        if text.isEmpty { return [] }
        
        var tags = tagStore.tags.filter { tag in
            !self.tags.contains(tag.name) && tag.name.localizedCaseInsensitiveContains(text)
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
            Section {
                WrappingHStack(alignment: .leading, verticalSpacing: 4) {
                    ForEach(tags, id: \.self) { tag in
                        TagView(tag, deletable: true)
                            .transition(.opacity)
                            .onTapGesture {
                                withAnimation {
                                    removeTag(tag)
                                }
                            }
                    }
                    
                    if allowAppend {
                        BackspaceDetectingTextField(placeholder: tags.isEmpty ? String(localized: "Add Tag", bundle: .module) : "", text: $text) { isEmpty in
                            if isEmpty {
                                if let last = tags.last {
                                    withAnimation {
                                        removeTag(last)
                                    }
                                }
                            }
                        } onSubmit: {
                            withAnimation {
                                appendTag(text)
                            }
                        }
                        .layoutStreched(minWidth: textFieldWidth)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Section {
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
}

/// This TextField is specifically designed for [THTagEditor]
struct BackspaceDetectingTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let onBackPressed: (Bool) -> Void
    let onSubmit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onBackPressed: onBackPressed, onSubmit: onSubmit)
    }
    
    func makeUIView(context: Context) -> CustomTextField {
        let textField = CustomTextField()
        textField.delegate = context.coordinator
        textField.onBackPressed = onBackPressed
        textField.placeholder = placeholder
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.returnKeyType = .done
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChange(textField:)), for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ uiView: CustomTextField, context: Context) {
        uiView.text = text
        uiView.placeholder = placeholder
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: CustomTextField, context: Context) -> CGSize? {
        guard
            let width = proposal.width,
            let height = proposal.height
        else { return nil }
        
        return CGSize(width: width, height: height)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let onBackPressed: (Bool) -> Void
        let onSubmit: () -> Void
        
        init(text: Binding<String>, onBackPressed: @escaping (Bool) -> Void, onSubmit: @escaping () -> Void) {
            self._text = text
            self.onBackPressed = onBackPressed
            self.onSubmit = onSubmit
        }
        
        @objc func textChange(textField: UITextField) {
            if textField.markedTextRange == nil {
                DispatchQueue.main.async { @MainActor [weak self] in
                    self?.text = textField.text ?? ""
                }
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return false
        }
    }
    
    class CustomTextField: UITextField {
        open var onBackPressed: ((Bool) -> Void)?
        
        override func deleteBackward() {
            onBackPressed?(text?.isEmpty == true)
            super.deleteBackward()
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var tags: [String] = ["Hello", "World!"]
    
    TagEditor($tags)
        .previewPrepared(wrapped: .list)
}
