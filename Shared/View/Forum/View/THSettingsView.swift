import SwiftUI
import PhotosUI

struct THSettingsView: View {
    @ObservedObject private var settings = THSettings.shared
    
    var body: some View {
        Section("Forum") {
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
            
            NavigationLink {
                NotificationSettingWrapper()
            } label: {
                Label("Push Notification Settings", systemImage: "bell.badge")
            }
            
            Toggle(isOn: $settings.showBanners) {
                Label("Show Activity Announcements", systemImage: "bell")
            }
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

fileprivate struct NotificationSettingWrapper: View {
    var body: some View {
        AsyncContentView {
            try await DXRequests.loadUserInfo()
        } content: { user in
            NotificationSetting(user)
        }
    }
}

fileprivate struct NotificationSetting: View {
    private let userId: Int
    @State private var favorite: Bool
    @State private var mention: Bool
    @State private var report: Bool
    @State private var showAlert = false
    
    init(_ user: DXUser) {
        self.userId = user.id
        let notify = user.config.notify
        self._favorite = State(initialValue: notify.contains("favorite"))
        self._mention = State(initialValue: notify.contains("mention"))
        self._report = State(initialValue: notify.contains("report"))
    }
    
    private func updateConfig() async {
        do {
            var notifyConfig: [String] = []
            if favorite {
                notifyConfig.append("favorite")
            }
            if mention {
                notifyConfig.append("mention")
            }
            if report {
                notifyConfig.append("report")
            }
            try await DXRequests.configNotification(userId: userId, config: notifyConfig)
        } catch {
            showAlert = true
        }
    }
    
    var body: some View {
        List {
            Toggle(isOn: $mention) {
                Label("Notify when my post is mentioned", systemImage: "arrowshape.turn.up.left")
            }
            .onChange(of: mention) { _ in
                Task { await updateConfig() }
            }
            
            Toggle(isOn: $favorite) {
                Label("Notify when favorited hole gets reply", systemImage: "star")
            }
            .onChange(of: favorite) { _ in
                Task { await updateConfig() }
            }
            
            Toggle(isOn: $report) {
                Label("Notify when my report is dealt", systemImage: "exclamationmark.triangle")
            }
            .onChange(of: report) { _ in
                Task { await updateConfig() }
            }
        }
        .alert("Update Notification Config Failed", isPresented: $showAlert) {
            
        }
        .navigationTitle("Push Notification Settings")
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
