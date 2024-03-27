import SwiftUI

struct THNotificationPage: View {
    var body: some View {
        AsyncContentView { () -> [THMessage] in
            return try await THRequests.loadMessages()
        } content: { messages in
            NotificationContent(messages: messages)
        }
    }
}

fileprivate struct NotificationContent: View {
    @ObservedObject private var appModel = DXModel.shared
    let messages: [THMessage]
    @State private var showMessageSheet = false
    
    var body: some View {
        THBackgroundList {
            ForEach(messages) { message in
                if let floor = message.floor {
                    NavigationListRow(value: THHoleLoader(floorId: floor.id)) {
                        THNotificationView(message: message)
                    }
                } else if let report = message.report {
                    NavigationListRow(value: THHoleLoader(floorId: report.floor.id)) {
                        THNotificationView(message: message)
                    }
                } else {
                    THNotificationView(message: message)
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if appModel.isAdmin {
                ToolbarItem {
                    Button {
                        showMessageSheet = true
                    } label: {
                        Image(systemName: "envelope")
                    }
                }
            }
        }
        .sheet(isPresented: $showMessageSheet) {
            THMessageSheet()
        }
    }
}
