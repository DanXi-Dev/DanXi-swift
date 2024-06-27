import PhotosUI
import SwiftUI
import SwiftUIX
import ViewUtils
import DanXiKit


public struct ForumEditor: View {
    @EnvironmentObject.Optional private var holeModel: HoleModel?
    @StateObject private var model: ForumEditorModel
    @Binding var content: String
    let initiallyFocused: Bool
    
    public init(content: Binding<String>, initiallyFocused: Bool = false) {
        _content = content
        self.initiallyFocused = initiallyFocused
        let model = ForumEditorModel(content: content.wrappedValue)
        self._model = StateObject(wrappedValue: model)
    }
    
    enum EditorMode {
        case edit, preview
    }
    
    @State private var editorMode: EditorMode = .edit
    @State private var showStickers = false
    @State private var presentPhotoPicker = false
    @FocusState private var textfieldFocus
    
    public var body: some View {
        previewSelector
            .onChange(of: model.content) { content = $0 }
            .onChange(of: content) { model.content = $0 }
            .photosPicker(isPresented: $presentPhotoPicker, selection: $model.photo, matching: .images)
            .sheet(isPresented: $showStickers) {
                stickerPicker
            }
            .alert(String(localized: "Uploading Image", bundle: .module), isPresented: $model.uploading) {
                Button(role: .cancel) {
                    model.uploadingTask?.cancel()
                    model.uploadingTask = nil
                } label: {
                    Text("Cancel", bundle: .module)
                }
            }
            .alert(String(localized: "Upload Image Failed", bundle: .module), isPresented: $model.showUploadError) {
                
            } message: {
                Text(model.uploadError?.localizedDescription ?? "")
            }
        
        if editorMode == .preview {
            preview
        } else {
            textView
        }
    }
    
    private var previewSelector: some View {
        Picker(selection: $editorMode) {
            Text("Edit", bundle: .module).tag(EditorMode.edit)
            Text("Preview", bundle: .module).tag(EditorMode.preview)
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(.zero)
    }
    
    private var preview: some View {
        Section {
            ForumContentPreview(content: model.content, contextFloors: holeModel?.floors.map({ $0.floor }) ?? [])
        }
    }
    
    private var textView: some View {
        Section {
            #if targetEnvironment(macCatalyst)
            toolbar
                .buttonStyle(.borderless) // Fixes hit-testing bug related to multiple buttons on a list row
            #endif
            
            TextEditor {
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
            .environmentObject(model)
            .frame(height: model.height ?? model.minHeight)
            .overlay(alignment: .topLeading) {
                if model.content.isEmpty {
                    Group {
                        if #available(iOS 17, *) {
                            Text("Enter post content", bundle: .module)
                                .foregroundStyle(.placeholder)
                        } else {
                            Text("Enter post content", bundle: .module)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 9)
                    .padding(.leading, 6)
                    .allowsHitTesting(false)
                }
            }
        } footer: {
            Text("TH Edit Alert", bundle: .module)
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
                                model.insertTextAtCursor("![](\(sticker.rawValue))")
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
    
    private var toolbar: some View {
        HStack(alignment: .center, spacing: 16) {
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    Button {
                        presentPhotoPicker = true
                    } label: {
                        Image(systemName: "photo")
                    }
                    
                    Button {
                        showStickers = true
                    } label: {
                        Image(systemName: "smiley")
                    }
                    
                    Divider()
                    
                    Button {
                        model.insertModifier(before: "**", after: "**")
                    } label: {
                        Image(systemName: "bold")
                    }
                    
                    Button {
                        model.insertModifier(before: "_", after: "_")
                    } label: {
                        Image(systemName: "italic")
                    }
                    
                    Button {
                        model.insertModifier(before: "`", after: "`")
                    } label: {
                        Image(systemName: "curlybraces")
                    }
                    
                    Button {
                        model.insertModifier(before: "~~", after: "~~")
                    } label: {
                        Image(systemName: "strikethrough")
                    }
                    
                    Button {
                        model.insertModifier(before: "$", after: "$")
                    } label: {
                        Image(systemName: "x.squareroot")
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
        .tint(.primary)
    }
}

@MainActor
private class ForumEditorModel: ObservableObject {
    @Published var content: String
    @Published var selection: Range<String.Index>?
    @Published var height: CGFloat?
    let minHeight: CGFloat = 200
    
    @Published var photo: PhotosPickerItem? {
        didSet {
            Task {
                await uploadPhoto()
            }
        }
    }
    @Published var uploading = false
    var uploadingTask: Task<Void, Error>?
    @Published var showUploadError = false
    @Published var uploadError: Error?
    
    init(content: String) {
        self.content = content
    }
    
    func insertModifier(before: String, after: String) {
        if let selection {
            let selectedContent = content[selection]
            content.replaceSubrange(selection, with: before + selectedContent + after)
            
            if selection.isEmpty {
                let position = content.index(selection.lowerBound, offsetBy: before.count)
                self.selection = position..<position
            } else {
                let newBefore = selection.lowerBound
                let newAfter = content.index(selection.upperBound, offsetBy: before.count + after.count)
                self.selection = newBefore..<newAfter
            }
        } else {
            content.append(before + after)
            let position = content.index(content.endIndex, offsetBy: -after.count)
            self.selection = position..<position
        }
    }
    
    func insertTextAtCursor(_ text: String) {
        if let selection {
            content.insert(contentsOf: text, at: selection.lowerBound)
            let newCursorPosition = content.index(selection.lowerBound, offsetBy: text.count)
            self.selection = newCursorPosition..<newCursorPosition
        } else {
            content.append(text)
        }
    }
    
    func uploadPhoto() async {
        guard let photo = photo,
              let data = try? await photo.loadTransferable(type: Data.self) else {
            return
        }
        
        uploadImageData(data: data)
    }
    
    func uploadImageData(data: Data) {
        uploadingTask = Task {
            uploading = true
            defer { uploading = false }
            
            do {
                let imageURL = try await GeneralAPI.uploadImage(data)
                insertTextAtCursor("![](\(imageURL.absoluteString))")
            } catch _ as CancellationError {
                // ignore
            } catch URLError.cancelled {
                // ignore
            } catch {
                showUploadError = true
                uploadError = error
            }
        }
    }
}

private struct TextEditor<Toolbar: View>: UIViewRepresentable {
    @EnvironmentObject private var model: ForumEditorModel
    
    @ViewBuilder let toolbar: () -> Toolbar
    
    class Coordinator: NSObject, UITextViewDelegate {
        unowned var model: ForumEditorModel
        
        init(model: ForumEditorModel) {
            self.model = model
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.model.content = textView.text
            }
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.model.selection = Range(textView.selectedRange, in: textView.text)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextViewWithImagePasting { data in
            model.uploadImageData(data: data)
        }
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
        textView.text = model.content
        if let selection = model.selection, selection.lowerBound < model.content.endIndex {
            textView.selectedRange = NSRange(selection, in: textView.text)
        }
        
        DispatchQueue.main.async { IQKeyboardManager.shared.reloadLayoutIfNeeded() }
        
        let newHeight = max(textView.contentSize.height, model.minHeight)
        if model.height != newHeight { // prevent circular update, without this, picker will not function properly
            DispatchQueue.main.async {
                model.height = newHeight
            }
        }
    }
}

class UITextViewWithImagePasting: UITextView {
    let pasteAction: (Data) -> Void
    
    init(pasteAction: @escaping (Data) -> Void) {
        self.pasteAction = pasteAction
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
            if let image = UIPasteboard.general.image,
               let data = image.pngData() {
                pasteAction(data)
            }
        } else {
            super.paste(sender)
        }
    }
}
