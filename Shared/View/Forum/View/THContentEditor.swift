import SwiftUI
import PhotosUI

struct THContentEditor: View {
    @Binding var content: String
    @State private var photo: PhotosPickerItem? = nil
    @State private var showUploadError = false
    @State private var showStickers = false
    
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
                
                Button {
                    showStickers = true
                } label: {
                    Label("Stickers", systemImage: "smiley")
                }
                .sheet(isPresented: $showStickers) {
                    stickerPicker
                }
                
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Enter post content")
                            .foregroundColor(.primary.opacity(0.25))
                            .padding(.top, 7)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $content)
                        .frame(height: 250)
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
