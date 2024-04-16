import PhotosUI
import SwiftUI
import ViewUtils

struct THContentEditor: View {
    @Binding var content: String
    @State private var cursorPosition: Int = 0
    @State private var selectOffset: Int = 0
    @State private var photo: PhotosPickerItem? = nil
    @State private var uploadError: String = ""
    @State private var showUploadError = false
    @State private var showStickers = false
    @State private var showPreview = false
    @Binding var runningImageUploadTasks: Int
    
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

        let cursorPosition = content.index(content.startIndex, offsetBy: cursorPosition)

        content.insert(contentsOf: "\n![Uploading \(taskID)...]\n", at: cursorPosition)
        do {
            let imageURL = try await THRequests.uploadImage(imageData)
            content.replace("\n![Uploading \(taskID)...]\n", with: "\n![](\(imageURL.absoluteString))\n")
        } catch {
            content = content.replacingOccurrences(of: "![Uploading \(taskID)...]", with: "")
            uploadError = error.localizedDescription
            showUploadError = true
        }
    }
    
    private var toolbar: some View {
        HStack(alignment: .center, spacing: 12) {
            PhotosPicker(selection: $photo, matching: .images) {
                Label("Upload Image", systemImage: "photo")
            }
            
            Button {
                showStickers = true
            } label: {
                Label("Stickers", systemImage: "smiley")
            }
            
            Spacer()
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
                THTextEditor(text: $content, cursorPosition: $cursorPosition, selectOffset: $selectOffset, placeholder: String(localized: "Enter post content"), minHeight: 200, uploadImageAction: uploadPhoto) {
                    toolbar
                        .padding()
                }
                .onAppear() {
                    IQKeyboardManager.shared.enable = true // Prevent keyboard from obstructing editor
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
                                content += " ![](\(sticker.rawValue))"
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
        THContentEditor(content: .constant("hello ![](dx_egg)"), runningImageUploadTasks: .constant(0))
    }
}
