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
                Form {
                    THTagField(tags: $settings.blockedTags)
                }
                .navigationTitle("Blocked Tags")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("Blocked Tags", systemImage: "tag.slash")
            }
        }
    }
}
