import SwiftUI
import ViewUtils
import DanXiKit
import Utils

struct MessageSheet: View {
    @State private var message = ""
    @State private var recipients = ""
    
    var body: some View {
        Sheet(String(localized: "Send Message", bundle: .module)) {
            guard let recipientsJSON = "[\(recipients)]".data(using: String.Encoding.utf8),
                  let parsedRecipients = try? JSONDecoder().decode([Int].self, from: recipientsJSON)else {
                let description = String(localized: "JSON format incorrect", bundle: .module)
                throw LocatableError(description)
            }
            try await ForumAPI.sendMessage(content: message, recipients: parsedRecipients)
        } content: {
            Section {
                TextEditor(text: $message)
            } header: {
                Text("Message Content", bundle: .module)
            }
            
            Section {
                TextField(String(localized: "Recipients", bundle: .module), text: $recipients)
            } footer: {
                Text("User IDs, separated by ASCII comma.", bundle: .module)
            }
        }
        .completed(!message.isEmpty)
        .warnDiscard(!message.isEmpty)
    }
}

#Preview {
    MessageSheet()
}
