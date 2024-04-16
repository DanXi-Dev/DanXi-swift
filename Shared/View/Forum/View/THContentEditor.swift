import SwiftUI
import PhotosUI

struct THContentEditor: View {
    @Binding var content: String
    @State private var photo: PhotosPickerItem? = nil
    @State private var showUploadError = false
    @State private var uploadError: String = ""
    @State private var showStickers = false
    @State private var showPreview = false
    
    @Binding var runningImageUploadTasks: Int
    
    private func uploadPhoto(_ photo: PhotosPickerItem?) async {
        guard let photo = photo,
              let imageData = try? await photo.loadTransferable(type: Data.self) else {
            return
        }
        
        runningImageUploadTasks += 1
        defer { runningImageUploadTasks -= 1 }
        
        let taskID = UUID().uuidString
        content.append("![Uploading \(taskID)...]")
        do {
            let imageURL = try await THRequests.uploadImage(imageData)
            content.replace("![Uploading \(taskID)...]", with: "![](\(imageURL.absoluteString))")
        } catch {
            content.replace("![Uploading \(taskID)...]", with: "")
            uploadError = error.localizedDescription
            showUploadError = true
        }
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
        
        if showPreview {
            Section {
                THFloorContent(content, interactable: false)
            }
        } else {
            Section {
                HStack(alignment: .center, spacing: 16) {
                    PhotosPicker(selection: $photo, matching: .images) {
                        Label("Upload Image", systemImage: "photo")
                    }
                    .onChange(of: photo) { photo in
                        Task {
                            await uploadPhoto(photo)
                        }
                    }
                    .alert("Upload Image Failed", isPresented: $showUploadError) { 
                        Text(uploadError)
                    }
                    
                    Button {
                        showStickers = true
                    } label: {
                        Label("Stickers", systemImage: "smiley")
                    }
                    .sheet(isPresented: $showStickers) {
                        stickerPicker
                    }
                    
                    Spacer()
                }
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)
                .tint(.primary)
                
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
