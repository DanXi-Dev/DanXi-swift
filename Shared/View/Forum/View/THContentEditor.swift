import SwiftUI
import PhotosUI
import Markdown

struct THContentEditor: View {
    @Binding var content: String
    @State private var photo: PhotosPickerItem? = nil
    @State private var showUploadError = false
    @State private var showStickers = false
    
    @State private var showExternalImageAlert = false
    @FocusState private var isEditing: Bool
    
    private func uploadPhoto(_ photo: PhotosPickerItem?) async throws {
        guard let photo = photo,
              let imageData = try await photo.loadTransferable(type: Data.self) else {
            return
        }
        
        let taskID = UUID().uuidString
        content.append("![Uploading \(taskID)...]")
        let imageURL = try await THRequests.uploadImage(imageData)
        content.replace("![Uploading \(taskID)...]", with: "![](\(imageURL.absoluteString))")
    }
    
    private func checkExternalImages() {
        Task {
            // do parsing in background to improve performance
            guard let attributed = try? AttributedString(markdown: content) else {
                return
            }
            
            for run in attributed.runs {
                if let url = run.imageURL {
                    if url.host()?.contains(IMAGE_BASE_URL) != true {
                        await MainActor.run {
                            showExternalImageAlert = true
                        }
                        return
                    }
                }
            }
        }
    }
    
    var body: some View {
        Group {
            Section {
                PhotosPicker(selection: $photo, matching: .images) {
                    Label("Upload Image", systemImage: "photo")
                }
                .onChange(of: photo) { photo in
                    Task {
                        do {
                            try await uploadPhoto(photo)
                        } catch {
                            showUploadError = true
                        }
                    }
                }
                .alert("Upload Image Failed", isPresented: $showUploadError) { }
                
//                Button {
//                    showStickers = true
//                } label: {
//                    Label("Stickers", systemImage: "smiley")
//                }
//                .sheet(isPresented: $showStickers) {
//                    stickerPicker
//                }
                
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Enter post content")
                            .foregroundColor(.primary.opacity(0.25))
                            .padding(.top, 7)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $content)
                        .focused($isEditing)
                        .frame(height: 250)
                        .onChange(of: isEditing) { isEditing in
                            if !isEditing {
                                checkExternalImages()
                            }
                        }
                        .alert("External Image", isPresented: $showExternalImageAlert) {
                            
                        } message: {
                            Text("external-image-alert")
                        }
                }


            } header: {
                Text("TH Edit Alert")
            }
            
            if !content.isEmpty {
                Section {
                    THFloorContent(content, interactable: false)
                } header: {
                    Text("Preview")
                }
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
                                content += " ^[\(sticker.rawValue)]"
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
        THContentEditor(content: .constant("Hello World ^[egg]"))
    }
}
