import SwiftUI
import ViewUtils

struct THNotificationPage: View {
    var body: some View {
        AsyncContentView { (_) -> [THMessage] in
            return try await THRequests.loadMessages()
        } content: { messages in
            NotificationContent(messages: messages)
                .watermark()
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct NotificationContent: View {
    @ObservedObject private var appModel = DXModel.shared
    let messages: [THMessage]
    
    var body: some View {
        Group {
            if messages.isEmpty {
                Text("No Content")
            } else {
                THBackgroundList {
                    ForEach(messages) { message in
                        if let floor = message.floor {
                            DetailLink(value: THHoleLoader(floorId: floor.id)) {
                                THNotificationView(message: message)
                            }
                        } else if let report = message.report {
                            DetailLink(value: THHoleLoader(floorId: report.floor.id)) {
                                THNotificationView(message: message)
                            }
                        } else {
                            THNotificationView(message: message)
                        }
                    }
                }
                .listStyle(.inset)
#if targetEnvironment(macCatalyst)
                .listRowBackground(Color.clear)
#endif
            }
        }
    }
}
