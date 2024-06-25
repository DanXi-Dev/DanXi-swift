import PhotosUI
import SwiftUI
import SwiftUIX
import ViewUtils
import DanXiKit

struct ForumEditor: View {
    @EnvironmentObject.Optional private var holeModel: HoleModel?
    
    @Binding var content: String
    @State private var selection: Range<String.Index>?
    @State private var presentPhotoPicker = false
    @State private var photo: PhotosPickerItem? = nil
    @State private var showUploadError = false
    @State private var uploadError: String = ""
    @State private var showStickers = false
    @State private var showPreview = false
    @FocusState private var textfieldFocus
    @Binding var runningImageUploadTasks: Int
    
    let initiallyFocused: Bool
    
    private func handlePickerResult(_ photo: PhotosPickerItem?) async throws {
        guard let photo = photo,
              let imageData = try await photo.loadTransferable(type: Data.self) else {
            return
        }
        await uploadPhoto(imageData)
    }
    
    func uploadPhoto(_ imageData: Data?) async {
        guard let imageData = imageData else {
            return
        }
        
        runningImageUploadTasks += 1
        defer { runningImageUploadTasks -= 1 }
        
        let taskID = UUID().uuidString
        addAtCursorPosition("![Uploading \(taskID)]")
        do {
            let imageURL = try await GeneralAPI.uploadImage(imageData)
            content.replace("![Uploading \(taskID)]", with: "![](\(imageURL.absoluteString))")
        } catch {
            content = content.replacingOccurrences(of: "![Uploading \(taskID)]", with: "")
            uploadError = error.localizedDescription
            showUploadError = true
        }
    }
    
    func addAtCursorPosition(_ newContent: String) {
        if let selection {
            content.insert(contentsOf: newContent, at: selection.lowerBound)
            // Set cursor position to the end of the inserted content
            let newCursorPosition = content.index(selection.lowerBound, offsetBy: newContent.count)
            self.selection = newCursorPosition..<newCursorPosition
        } else {
            content.append(newContent)
        }
    }
    
    func addMarkdownModifier(beginning: String, end: String) {
        if let selection {
            let selectedContent = content[selection]
            content.replaceSubrange(selection, with: beginning + selectedContent + end)
            if selection.isEmpty {
                let position = content.index(selection.lowerBound, offsetBy: beginning.count)
                self.selection = position..<position
            } else {
                let newBegin = selection.lowerBound
                let newEnd = content.index(selection.upperBound, offsetBy: beginning.count + end.count)
                self.selection = newBegin..<newEnd
            }
        } else {
            content.append(beginning + end)
            let position = content.index(content.endIndex, offsetBy: -end.count)
            self.selection = position..<position
        }
    }
    
    func addToBeginningOfLine(_ newContent: String) {
        if let selection {
            let cursorPosition = selection.lowerBound
            let lineBreak = content[..<(cursorPosition)].lastIndex(of: "\n")
            guard let lineBreak else {
                self.content.insert(contentsOf: newContent, at: content.startIndex)
                let newCursorPosition = content.index(cursorPosition, offsetBy: newContent.count)
                self.selection = newCursorPosition..<newCursorPosition
                return
            }
            let lineStart = content.index(after: lineBreak)
            self.content.insert(contentsOf: newContent, at: lineStart)
            let newCursorPosition = content.index(cursorPosition, offsetBy: newContent.count)
            self.selection = newCursorPosition..<newCursorPosition
        } else {
            self.content.insert(contentsOf: newContent, at: content.startIndex)
            let newCursorPosition = content.index(content.startIndex, offsetBy: newContent.count)
            self.selection = newCursorPosition..<newCursorPosition
        }
    }
    
    private var toolbar: some View {
        HStack(alignment: .center, spacing: 16) {
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    Button(action: {
                        textfieldFocus = false
                        presentPhotoPicker = true
                    }, label: {
                        Label(String(localized: "Upload Image", bundle: .module), systemImage: "photo")
                    })
                    .photosPicker(isPresented: $presentPhotoPicker, selection: $photo, matching: .images)
                    
                    Button {
                        showStickers = true
                    } label: {
                        Label(String(localized: "Stickers", bundle: .module), systemImage: "smiley")
                    }
                    
                    Divider()
                    
                    Button {
                        addMarkdownModifier(beginning: "**", end: "**")
                    } label: {
                        Label(String(localized: "Bold", bundle: .module), systemImage: "bold")
                    }
                    
                    Button {
                        addMarkdownModifier(beginning: "_", end: "_")
                    } label: {
                        Label(String(localized: "Italic", bundle: .module), systemImage: "italic")
                    }
                    
                    Button {
                        addMarkdownModifier(beginning: "`", end: "`")
                    } label: {
                        Label(String(localized: "Code", bundle: .module), systemImage: "curlybraces")
                    }
                    
                    Button {
                        addMarkdownModifier(beginning: "$", end: "$")
                    } label: {
                        Label(String(localized: "Math", bundle: .module), systemImage: "x.squareroot")
                    }
                    
                    Button {
                        addToBeginningOfLine("> ")
                    } label: {
                        Label(String(localized: "Quote", bundle: .module), systemImage: "increase.quotelevel")
                    }
                    
                    Button {
                        addToBeginningOfLine("- ")
                    } label: {
                        Label(String(localized: "List", bundle: .module), systemImage: "list.bullet")
                    }
                    
                    Button {
                        addToBeginningOfLine("1. ")
                    } label: {
                        Label(String(localized: "Numbered List", bundle: .module), systemImage: "list.number")
                    }
                    
                    Button {
                        addMarkdownModifier(beginning: "[", end: "](https://)")
                    } label: {
                        Label(String(localized: "Link", bundle: .module), systemImage: "link")
                    }
                }
            }
            .scrollIndicators(.hidden)
            
#if !targetEnvironment(macCatalyst)
            Button {
                textfieldFocus = false
            } label: {
                Text("Done", bundle: .module)
            }
#endif
        }
        .labelStyle(.iconOnly)
        .tint(.primary)
    }
    
    var body: some View {
        Picker(selection: $showPreview) {
            Text("Edit", bundle: .module).tag(false)
            Text("Preview", bundle: .module).tag(true)
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(.zero)
        .onChange(of: photo) { photo in
            Task {
                do {
                    try await handlePickerResult(photo)
                } catch {
                    showUploadError = true
                }
            }
        }
        .alert(String(localized: "Upload Image Failed", bundle: .module), isPresented: $showUploadError) { } message: {
            Text(uploadError)
        }
        .sheet(isPresented: $showStickers) {
            stickerPicker
        }
        
        if showPreview {
            Section {
                ForumContentPreview(content: content, contextFloors: holeModel?.floors.map({ $0.floor }) ?? [])
            }
        } else {
            Section {
            #if targetEnvironment(macCatalyst)
                toolbar
                    .buttonStyle(.borderless) // Fixes hit-testing bug related to multiple buttons on a list row
            #endif
                THTextEditor(text: $content, selection: $selection, placeholder: String(localized: "Enter post content", bundle: .module), minHeight: 200, uploadImageAction: uploadPhoto) {
                    Divider()
                    toolbar
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                        .padding(.top, 4)
                }
                .focused($textfieldFocus)
                .onAppear() {
                    IQKeyboardManager.shared.enable = true // Prevent keyboard from obstructing editor
                    if initiallyFocused {
                        textfieldFocus = true
                    }
                }
                .onDisappear() {
                    IQKeyboardManager.shared.enable = false // Disable to prevent side effects to other TextFields
                }
                
            } footer: {
                Text("TH Edit Alert", bundle: .module)
            }
        }
    }
    
    private var stickerPicker: some View {
        NavigationStack {
            Form {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())]) {
                        ForEach(Sticker.allCases, id: \.self.rawValue) { sticker in
                            Button {
                                addAtCursorPosition("![](\(sticker.rawValue))")
                                showStickers = false
                            } label: {
                                sticker.image
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showStickers = false
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                }
            }
            .navigationTitle(String(localized: "Stickers", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

/// This TextField is specifically designed as a Text Editor for Tree Hole
private struct THTextEditor<Toolbar: View>: View {
    @Binding var text: String
    @Binding var selection: Range<String.Index>?
    let placeholder: String?
    let minHeight: CGFloat
    let uploadImageAction: (Data?) async throws -> Void
    @ViewBuilder let toolbar: () -> Toolbar
    @State private var height: CGFloat?
    
    var body: some View {
        THTextEditorUIView(textDidChange: textDidChange,
                           uploadImageAction: uploadImageAction,
                           text: $text,
                           selection: $selection,
                           toolbar: toolbar)
        .frame(height: height ?? minHeight)
        .overlay(alignment: .topLeading) {
            if let placeholder, text.isEmpty {
                Group {
                    if #available(iOS 17, *) {
                        Text(placeholder)
                            .foregroundStyle(.placeholder)
                    } else {
                        Text(placeholder)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 9)
                .padding(.leading, 6)
                .allowsHitTesting(false)
            }
        }
    }
    
    private func textDidChange(_ textView: UITextView) {
        height = max(textView.contentSize.height, minHeight)
        DispatchQueue.main.async { IQKeyboardManager.shared.reloadLayoutIfNeeded() }
    }
}

private struct THTextEditorUIView<Toolbar: View>: UIViewRepresentable {
    typealias UIViewType = UITextView
    
    let textDidChange: (UITextView) -> Void
    let uploadImageAction: (Data?) async throws -> Void
    @Binding var text: String
    @Binding var selection: Range<String.Index>?
    @ViewBuilder let toolbar: () -> Toolbar
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, selection: $selection, textDidChange: textDidChange)
    }
    
    class TextViewWithImagePasting: UITextView {
        let uploadImageAction: (Data?) async throws -> Void
        
        init(uploadImageAction: @escaping (Data?) async throws -> Void) {
            self.uploadImageAction = uploadImageAction
            super.init(frame: .zero, textContainer: nil)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            if action == #selector(paste(_:)) {
                return true
            }
            return super.canPerformAction(action, withSender: sender)
        }
        
        override func paste(_ sender: Any?) {
            if UIPasteboard.general.hasImages && !UIPasteboard.general.hasStrings && !UIPasteboard.general.hasURLs {
                if let image = UIPasteboard.general.image {
                    Task {
                        try await uploadImageAction(image.pngData())
                    }
                }
            } else {
                super.paste(sender)
            }
        }
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = TextViewWithImagePasting(uploadImageAction: uploadImageAction)
        textView.isEditable = true
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = false
        
        let toolbarHostingVC = UIHostingController(rootView: toolbar())
        toolbarHostingVC.sizingOptions = [.intrinsicContentSize]
        toolbarHostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarHostingVC.view.backgroundColor = .tertiarySystemBackground
        textView.inputAccessoryView = toolbarHostingVC.view
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
        if let selection {
            textView.selectedRange = NSRange(selection, in: textView.text)
        }
        DispatchQueue.main.async {
            self.textDidChange(textView)
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var selection: Range<String.Index>?
        let textDidChange: (UITextView) -> Void
        
        init(text: Binding<String>, selection: Binding<Range<String.Index>?>, textDidChange: @escaping (UITextView) -> Void) {
            self._text = text
            self._selection = selection
            self.textDidChange = textDidChange
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async { @MainActor [weak self] in
                self?.text = textView.text
                self?.textDidChange(textView)
            }
        }
        
        // customize the menu of textfield
        func textView(
            _ textView: UITextView,
            editMenuForTextIn range: NSRange,
            suggestedActions: [UIMenuElement]
        ) -> UIMenu? {
            return nil
            
            // todo I'll do this later
            
            //            guard range.length > 0 else { return nil }
            //
            //            var customActions: [UIMenuElement] = []
            //
            //            if range.length > 0, let textRange = Range(range, in: textView.text) {
            //                let boldAction = UIAction(title: "Bold") { _ in
            //                    let selectedText = textView.text[textRange]
            //                    let boldedText = "**\(selectedText)**"
            //
            //                    let replacedText = textView.text.replacingCharacters(in: textRange, with: boldedText)
            //
            //                    textView.text = replacedText
            //                    self.parent.text = replacedText
            //
            //                    let newCursorPosition = textView.position(from: textView.beginningOfDocument, offset: range.location + boldedText.count)
            //                    if let newCursorPosition = newCursorPosition {
            //                        textView.selectedTextRange = textView.textRange(from: newCursorPosition, to: newCursorPosition)
            //                    }
            //                }
            //
            //                let italicAction = UIAction(title: "Italic") { _ in
            //                    let selectedText = textView.text[textRange]
            //                    let italicText = "*\(selectedText)*"
            //
            //                    let replacedText = textView.text.replacingCharacters(in: textRange, with: italicText)
            //
            //                    textView.text = replacedText
            //                    self.parent.text = replacedText
            //
            //                    let newCursorPosition = textView.position(from: textView.beginningOfDocument, offset: range.location + italicText.count)
            //                    if let newCursorPosition = newCursorPosition {
            //                        textView.selectedTextRange = textView.textRange(from: newCursorPosition, to: newCursorPosition)
            //                    }
            //                }
            //
            //                customActions.append(boldAction)
            //                customActions.append(italicAction)
            //            }
            //
            //            return UIMenu(children: customActions + suggestedActions)
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async { @MainActor [weak self] in
                self?.selection = Range(textView.selectedRange, in: textView.text)
            }
        }
    }
}
