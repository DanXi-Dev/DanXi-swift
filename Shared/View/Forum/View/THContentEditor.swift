import PhotosUI
import SwiftUI
import ViewUtils

struct THContentEditor: View {
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
            let imageURL = try await THRequests.uploadImage(imageData)
            content.replace("![Uploading \(taskID)]", with: "![](\(imageURL.absoluteString))")
        } catch {
            content = content.replacingOccurrences(of: "![Uploading \(taskID)]", with: "")
            uploadError = error.localizedDescription
            showUploadError = true
        }
    }
    
    func addAtCursorPosition(_ newContent: String) {
        if let selection, selection.upperBound <= content.endIndex {
            content.insert(contentsOf: newContent, at: selection.lowerBound)
        } else {
            content.append(newContent)
        }
    }
    
    func addMarkdownModifier(beginning: String, end: String) {
        if let selection, selection.upperBound <= content.endIndex {
            let selectedContent = content[selection]
            content.replaceSubrange(selection, with: beginning + selectedContent + end)
            if selection.isEmpty {
                let position = content.index(selection.lowerBound, offsetBy: beginning.count)
                self.selection = position..<position
            }
        } else {
            content.append(beginning + end)
            let position = content.index(content.endIndex, offsetBy: -end.count)
            self.selection = position..<position
        }
    }
    
    func addToBeginningOfLine(_ newContent: String) {
        if let selection, selection.upperBound <= content.endIndex {
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
                        Label("Upload Image", systemImage: "photo")
                    })
                    .photosPicker(isPresented: $presentPhotoPicker, selection: $photo, matching: .images)
                    
                    Button {
                        showStickers = true
                    } label: {
                        Label("Stickers", systemImage: "smiley")
                    }
                    
                    Divider()
                    
                    Button {
                        addMarkdownModifier(beginning: "**", end: "**")
                    } label: {
                        Label("Bold", systemImage: "bold")
                    }
                    
                    Button {
                        addMarkdownModifier(beginning: "_", end: "_")
                    } label: {
                        Label("Italic", systemImage: "italic")
                    }
                    
                    Button {
                        addMarkdownModifier(beginning: "`", end: "`")
                    } label: {
                        Label("Code", systemImage: "curlybraces")
                    }
                    
                    Button {
                        addMarkdownModifier(beginning: "$", end: "$")
                    } label: {
                        Label("Math", systemImage: "x.squareroot")
                    }
                    
                    Button {
                        addToBeginningOfLine("> ")
                    } label: {
                        Label("Quote", systemImage: "increase.quotelevel")
                    }
                    
                    Button {
                        addToBeginningOfLine("- ")
                    } label: {
                        Label("List", systemImage: "list.bullet")
                    }
                    
                    Button {
                        addToBeginningOfLine("1. ")
                    } label: {
                        Label("Numbered List", systemImage: "list.number")
                    }
                    
                    Button {
                        addMarkdownModifier(beginning: "[", end: "](https://)")
                    } label: {
                        Label("Link", systemImage: "link")
                    }
                }
            }
            .scrollIndicators(.hidden)
            
#if !targetEnvironment(macCatalyst)
            Button {
                textfieldFocus = false
            } label: {
                Text("Done")
            }
#endif
        }
        .labelStyle(.iconOnly)
        .tint(.primary)
    }
    
    var body: some View {
        Picker(selection: $showPreview) {
            Text("Edit").tag(false)
            Text("Preview").tag(true)
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
        .alert("Upload Image Failed", isPresented: $showUploadError) { } message: {
            Text(uploadError)
        }
        .sheet(isPresented: $showStickers) {
            stickerPicker
        }
        
        if showPreview {
            Section {
                THFloorContent(content, interactable: false)
            }
        } else {
            Section {
#if targetEnvironment(macCatalyst)
                toolbar
                    .buttonStyle(.borderless) // Fixes hit-testing bug related to multiple buttons on a list row
#endif
                THTextEditor(text: $content, selection: $selection, placeholder: String(localized: "Enter post content"), minHeight: 200, uploadImageAction: uploadPhoto) {
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
                Text("TH Edit Alert")
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
                        ForEach(THSticker.allCases, id: \.self.rawValue) { sticker in
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
                        Text("Cancel")
                    }
                }
            }
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    List {
        THContentEditor(content: .constant("hello ![](dx_egg)"), runningImageUploadTasks: .constant(0), initiallyFocused: false)
    }
}
