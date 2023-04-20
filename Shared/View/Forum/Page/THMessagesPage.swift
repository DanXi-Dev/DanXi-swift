import SwiftUI

struct THNotificationPage: View {
    var body: some View {
        AsyncContentView { () -> [THMessage] in
            return try await THRequests.loadMessages()
        } content: { messages in
            THNotificationPageContent(messages: messages)
        }
    }
}

fileprivate struct THNotificationPageContent: View {
    let messages: [THMessage]
    
    var body: some View {
        List {
            ForEach(messages) { message in
                if let floor = message.floor {
                    NavigationPlainLink(value: THHoleLoader(floorId: floor.id)) {
                        THNotificationView(message: message)
                    }
                } else if let report = message.report {
                    NavigationPlainLink(value: THHoleLoader(floorId: report.floor.id)) {
                        THNotificationView(message: message)
                    }
                } else {
                    THNotificationView(message: message)
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Notifications")
    }
}
