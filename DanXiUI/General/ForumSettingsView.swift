import SwiftUI
import ViewUtils
import DanXiKit

public struct ForumSettingsView: View {
    public init() { }
    
    public var body: some View {
        Section("Forum") {
            ForEach(ForumSettingsSection.allCases) { section in
                DetailLink(value: section) {
                    section.label.navigationStyle()
                }
            }
        }
    }
}

public enum ForumSettingsSection: Identifiable, Hashable, CaseIterable {
    case notification
    case nsfw
    case blocked
    
    public var id: ForumSettingsSection {
        self
    }
    
    public var label: some View {
        switch self {
        case .notification:
            Label("Push Notification Settings", systemImage: "app.badge")
        case .nsfw:
            Label("NSFW Content", systemImage: "eye.square")
        case .blocked:
            Label("Blocked Content", systemImage: "hand.raised.app")
        }
    }
    
    @ViewBuilder
    public var destination: some View {
        switch self {
        case .notification:
            NotificationSettingWrapper()
        case .nsfw:
            NSFWSettings()
        case .blocked:
            BlockedContent()
        }
    }
}

fileprivate struct NSFWSettings: View {
    @ObservedObject private var settings = ForumSettings.shared
    
    var body: some View {
        Form {
            Picker(selection: $settings.sensitiveContent) {
                Text("Show").tag(ForumSettings.SensitiveContentSetting.show)
                Text("Fold").tag(ForumSettings.SensitiveContentSetting.fold)
                Text("Hide").tag(ForumSettings.SensitiveContentSetting.hide)
            }
            .pickerStyle(.inline)
        }
        .navigationTitle("NSFW Content")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct BlockedContent: View {
    @ObservedObject private var settings = ForumSettings.shared
    
    var body: some View {
        Form {
            Section("Blocked Tags") {
                TagEditor($settings.blockedTags)
            }
            
            Section("Blocked Holes") {
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
            
            if settings.blockedHoles.isEmpty {
                Section("You haven't blocked any holes. You can a block hole by pressing and holding it and select \"Block Hole\" in the menu.") {}
                    .textCase(.none)
            }
        }
        .navigationTitle("Blocked Content")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingWrapper: View {
    var body: some View {
        AsyncContentView {
            async let profile = ForumAPI.getProfile()
            async let authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            return try await (profile, authorizationStatus)
        } content: { (profile: Profile, authorizationStatus: UNAuthorizationStatus) in
            NotificationSetting(profile, authorizationStatus)
        }
        .navigationTitle("Push Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct NotificationSetting: View {
    private let userId: Int
    private let authorizationStatus: UNAuthorizationStatus
    private let notificationSettingsURL: URL?
    @State private var favorite: Bool
    @State private var mention: Bool
    @State private var report: Bool
    @State private var showAlert = false
    
    init(_ user: Profile, _ authorizationStatus: UNAuthorizationStatus) {
        self.userId = user.id
        self.authorizationStatus = authorizationStatus
        let notify = user.notificationConfiguration
        self._favorite = State(initialValue: notify.contains("favorite"))
        self._mention = State(initialValue: notify.contains("mention"))
        self._report = State(initialValue: notify.contains("report"))
        
        if let url = URL(string: UIApplication.openNotificationSettingsURLString), UIApplication.shared.canOpenURL(url) {
            notificationSettingsURL = url
        } else {
            notificationSettingsURL = nil
        }
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
            let newProfile = try await ForumAPI.updateUserSettings(userId: userId, notificationConfiguration: notifyConfig)
            await MainActor.run {
                ProfileStore.shared.profile = newProfile
            }
        } catch {
            showAlert = true
        }
    }
    
    var body: some View {
        List {
            if authorizationStatus != .authorized {
                Section {
                    Button {
                        if let url = notificationSettingsURL {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Push Notification Not Authorized", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            
            Section {
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
            .disabled(authorizationStatus != .authorized)
            
            if let url = notificationSettingsURL {
                Section {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Text("Open Notification Settings")
                    }
                }
            }
        }
        .alert("Update Notification Config Failed", isPresented: $showAlert) {}
        .labelStyle(.titleOnly)
    }
}
