import DanXiKit
import SwiftUI
import ViewUtils

@available(iOS 18.0, *)
struct DantaSessionList: View {
    let chat: DantaChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Button {
                    chat.switchSession(to: nil)
                    dismiss()
                } label: {
                    Label { Text("New Chat", bundle: .module) } icon: { Image(systemName: "square.and.pencil") }
                }
            }
            Section {
                if chat.isLoadingSessions {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
                if let issue = chat.sessionsIssue {
                    DantaErrorNotice(issue: issue, isRetrying: chat.isLoadingSessions) { await chat.loadSessions() }
                } else if chat.sessions.isEmpty, chat.placeholderSessionId == nil, !chat.isLoadingSessions {
                    Text("No conversations yet.", bundle: .module)
                        .foregroundStyle(.secondary)
                }
                ForEach(chat.sessions) { session in
                    sessionRow(id: session.id, title: session.title)
                }
                if let id = chat.placeholderSessionId {
                    sessionRow(id: id, title: String(localized: "Conversation", bundle: .module))
                }
            }
        }
        .navigationTitle(String(localized: "Chats", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { dismiss() } label: { Text("Done", bundle: .module) }
            }
        }
        .task { await chat.loadSessions() }
        .refreshable { await chat.loadSessions() }
    }

    private func sessionRow(id: Int, title: String) -> some View {
        Button {
            chat.switchSession(to: id)
            dismiss()
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                if id == chat.channelId {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            }
        }
    }
}
