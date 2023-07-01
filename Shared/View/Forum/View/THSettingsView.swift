import SwiftUI
import PhotosUI

struct THSettingsView: View {
    @ObservedObject private var settings = THSettings.shared
    
    var body: some View {
        Section("Tree Hole") {
            Picker(selection: $settings.sensitiveContent, label: Label("NSFW Content", systemImage: "eye.slash")) {
                Text("Show").tag(THSettings.SensitiveContentSetting.show)
                Text("Fold").tag(THSettings.SensitiveContentSetting.fold)
                Text("Hide").tag(THSettings.SensitiveContentSetting.hide)
            }
            
            NavigationLink {
                BlockedTags()
            } label: {
                Label("Blocked Tags", systemImage: "tag.slash")
            }
            
            NavigationLink {
                BlockedHoles()
            } label: {
                Label("Blocked Holes", systemImage: "eye.slash")
            }
            
            Toggle(isOn: $settings.screenshotAlert) {
                Label("Screenshot Alert", systemImage: "camera.viewfinder")
            }
            
            Toggle(isOn: $settings.showBanners) {
                Label("Show Activity Announcements", systemImage: "bell")
            }
            
            ImagePicker()
        }
    }
}

fileprivate struct BlockedTags: View {
    @ObservedObject private var settings = THSettings.shared
    
    var body: some View {
        Form {
            THTagEditor($settings.blockedTags)
        }
        .navigationTitle("Blocked Tags")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct BlockedHoles: View {
    @ObservedObject private var settings = THSettings.shared
    
    var body: some View {
        List {
            ForEach(settings.blockedHoles, id: \.self) { holeId in
                Text("#\(String(holeId))")
                    .swipeActions {
                        Button(role: .destructive) {
                            if let idx = settings.blockedHoles.firstIndex(of: holeId) {
                                withAnimation {
                                    _ = settings.blockedHoles.remove(at: idx)
                                }
                            }
                        } label: {
                            Image(systemName: "trash")
                        }

                    }
            }
        }
        .navigationTitle("Blocked Holes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct ImagePicker: View {
    @ObservedObject private var settings = THSettings.shared
    @State private var photoItem: PhotosPickerItem? = nil
    
    var body: some View {
        Group {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Pick a Background Photo", systemImage: "photo")
            }
            
            if settings.backgroundImage != nil {
                Button {
                    settings.setBackgroundImage(nil)
                } label: {
                    Label("Remove Background Photo", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .onChange(of: photoItem) { item in
            settings.setBackgroundImage(item)
        }
    }
}
