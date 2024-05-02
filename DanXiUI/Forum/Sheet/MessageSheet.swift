import SwiftUI
import ViewUtils
import DanXiKit

struct MessageSheet: View {
    @State private var message = ""
    @State private var recipients = ""
    
    var body: some View {
        Sheet("Send Message") {
            guard let recipientsJSON = "[\(recipients)]".data(using: String.Encoding.utf8),
                  let parsedRecipients = try? JSONDecoder().decode([Int].self, from: recipientsJSON)else {
                throw URLError(.badURL)
            }
            try await ForumAPI.sendMessage(content: message, recipients: parsedRecipients)
        } content: {
            Section {
                TextEditor(text: $message)
            } header: {
                Text("Message Content")
            }
            
            Section {
                TextField("Recipients", text: $recipients)
            } footer: {
                Text("User IDs, separated by ASCII comma.")
            }
        }
        .completed(!message.isEmpty)
        .warnDiscard(!message.isEmpty)
    }
}
