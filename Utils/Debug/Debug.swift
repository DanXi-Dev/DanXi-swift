import SwiftUI

public func message(_ message: String, data: Data? = nil) {
    MessageCenter.shared.messages.append(Message(date: Date(), message: message, data: data))
}

class MessageCenter {
    static let shared = MessageCenter()
    
    var messages: [Message] = []
    
    func exportMessages() -> Messages {
        let messages = Messages(date: Date(), messages: messages)
        return messages
    }
}

struct Messages: Codable {
    let date: Date
    let messages: [Message]
}

extension Messages: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { messages in
            let encoder = JSONEncoder()
            return try encoder.encode(messages)
        }
    }
}

struct Message: Codable {
    let date: Date
    let message: String
    let data: Data?
}

public struct MessageExportButton: View {
    let messages: Messages
    
    public var body: some View {
        ShareLink(item: messages, preview: SharePreview("导出消息"))
    }
}
