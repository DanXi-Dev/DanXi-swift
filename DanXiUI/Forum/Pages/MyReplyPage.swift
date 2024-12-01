import SwiftUI
import ViewUtils
import DanXiKit

struct MyReplyPage: View {
    @ObservedObject private var settings = ForumSettings.shared
    
    var body: some View {
        ForumList {
            AsyncCollection { floors in
                try await ForumAPI.listMyFloors(offset: floors.count)
            } content: { floor in
                if !settings.hiddenMyReplies.contains(floor.id) {
                    Section {
                        FoldedView(expand: !floor.deleted) {
                            Text("Deleted Floor", bundle: .module)
                                .foregroundStyle(.secondary)
                                .tint(.primary)
                        } content: {
                            DetailLink(value: HoleLoader(floor)) {
                                SimpleFloorView(floor: floor)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                        .swipeActions {
                            Button(role: .destructive) {
                                withAnimation {
                                    settings.hiddenMyReplies.append(floor.id)
                                }
                            } label: {
                                Label {
                                    Text("Hide", bundle: .module)
                                } icon: {
                                    Image(systemName: "eye.slash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "My Reply", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .watermark()
    }
}
