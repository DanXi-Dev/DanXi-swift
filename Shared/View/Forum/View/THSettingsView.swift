import SwiftUI

struct THSettingsView: View {
    @ObservedObject var settings = THSettings.shared
    
    var body: some View {
        Section("Tree Hole") {
            Picker(selection: $settings.sensitiveContent, label: Label("NSFW Content", systemImage: "eye.slash")) {
                Text("Show").tag(THSettings.SensitiveContentSetting.show)
                Text("Fold").tag(THSettings.SensitiveContentSetting.fold)
                Text("Hide").tag(THSettings.SensitiveContentSetting.hide)
            }
            
            NavigationLink {
                THBlockedTagsEdit()
            } label: {
                Label("Blocked Tags", systemImage: "tag.slash")
            }
            
            NavigationLink {
                THBlockedHolesEdit()
            } label: {
                Label("Blocked Holes", systemImage: "eye.slash")
            }
        }
    }
}

fileprivate struct THBlockedTagsEdit: View {
    @ObservedObject var settings = THSettings.shared
    
    var body: some View {
        Form {
            THTagEditor($settings.blockedTags)
        }
        .navigationTitle("Blocked Tags")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct THBlockedHolesEdit: View {
    @ObservedObject var settings = THSettings.shared
    
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
