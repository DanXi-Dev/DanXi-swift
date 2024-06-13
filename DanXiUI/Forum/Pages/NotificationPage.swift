import SwiftUI
import ViewUtils
import DanXiKit

struct NotificationPage: View {
    var body: some View {
        AsyncContentView {
            try await ForumAPI.listMessages()
        } content: { messages in
            NotificationContent(messages: messages)
                .watermark()
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationContent: View {
    let messages: [Message]
    
    var body: some View {
        Group {
            if messages.isEmpty {
                Text("No Content")
            } else {
                ForumList {
                    ForEach(messages) { message in
                        if let floor = message.floor {
                            DetailLink(value: HoleLoader(floorId: floor.id)) {
                                NotificationView(message: message)
                            }
                        } else if let report = message.report {
                            DetailLink(value: HoleLoader(floorId: report.floor.id)) {
                                NotificationView(message: message)
                            }
                        } else {
                            NotificationView(message: message)
                        }
                    }
                    #if targetEnvironment(macCatalyst)
                    .listRowBackground(Color.clear)
                    #endif
                }
                .listStyle(.inset)
            }
        }
    }
}

private struct NotificationView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top) {
            message.icon
                .padding(.trailing)
                .padding(.vertical)
            
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(message.title)
                        .font(.headline)
                    Spacer()
                    Text(message.timeCreated.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if message.type == .permission {
                    Text(message.description)
                }
                
                if let floor = message.floor {
                    GroupBox {
                        SimpleFloorView(floor: floor)
                    }
                } else if let report = message.report {
                    GroupBox {
                        SimpleFloorView(floor: report.floor)
                    }
                } else if message.type == .mail {
                    GroupBox {
                        HStack {
                            Text(message.description)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

extension Message {
    public var icon: Image {
        switch self.type {
        case .favorite:
            Image(systemName: "bell")
        case .reply:
            Image(systemName: "arrowshape.turn.up.left")
        case .mention:
            Image(systemName: "quote.bubble")
        case .modify:
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
        case .permission:
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
        case .report:
            Image(systemName: "exclamationmark.circle")
        case .reportDealt:
            Image(systemName: "exclamationmark.circle")
        case .mail:
            Image(systemName: "envelope")
        }
    }
    
    public var title: LocalizedStringKey {
        switch self.type {
        case .favorite:
            "New reply in favorites"
        case .reply:
            "New reply"
        case .mention:
            "Mentioned"
        case .modify:
            "Violation notice"
        case .permission:
            "Ban notice"
        case .report:
            "New Report"
        case .reportDealt:
            "Report feedback"
        case .mail:
            "System mail"
        }
    }
}

