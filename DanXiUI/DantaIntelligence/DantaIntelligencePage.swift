import DanXiKit
import SwiftUI

@available(iOS 18.0, *)
public struct DantaIntelligencePage: View {
    @State private var viewModel: OpenClawChatViewModel
    @State private var showingSessions = false
    
    public init() {
        let transport = DantaIntelligenceChatTransport()
        self._viewModel = State(initialValue: OpenClawChatViewModel(
            sessionKey: DantaIntelligenceSession.newSessionKey,
            transport: transport))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            statusBar
            messageList
            composer
        }
        .navigationTitle("Danta Intelligence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .topBarTrailing)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSessions = true
                    viewModel.refreshSessions(limit: 50)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel("Conversation History")
            }
        }
        .sheet(isPresented: $showingSessions) {
            NavigationStack {
                sessionList
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            viewModel.load()
        }
    }
    
    private var statusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.healthOK ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            Text(viewModel.healthOK ? "Connected" : "Connecting")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(currentSessionLabel)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    let hasStreamingResponse = hasVisibleAssistantResponse(viewModel.streamingAssistantText)
                    
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .padding(.top, 48)
                    }
                    
                    ForEach(viewModel.messages) { message in
                        DantaMessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.pendingRunCount > 0 && !hasStreamingResponse {
                        DantaThinkingBubble()
                            .id("thinking")
                    }
                    
                    if let streamingText = viewModel.streamingAssistantText,
                       hasStreamingResponse {
                        DantaStreamingBubble(text: streamingText)
                            .id("streaming")
                    }
                    
                    if let errorText = viewModel.errorText,
                       !errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        DantaErrorBubble(text: errorText)
                            .id("error")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 18)
            }
            .background(Color(.systemGroupedBackground))
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.streamingAssistantText ?? "") { _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.pendingRunCount) { _ in
                scrollToBottom(proxy)
            }
        }
    }
    
    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "Ask Danta Intelligence",
                text: Binding(
                    get: { viewModel.input },
                    set: { viewModel.input = $0 }),
                axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .layoutPriority(1)
            
            sendButton
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
    
    @ViewBuilder
    private var sendButton: some View {
        let button = Button {
            viewModel.send()
        } label: {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 34, height: 34)
        }
        .accessibilityLabel("Send")
        .disabled(!viewModel.canSend)
        
        if #available(iOS 26.0, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }
    
    private var sessionList: some View {
        List {
            Section {
                Button {
                    viewModel.switchSession(to: DantaIntelligenceSession.newSessionKey)
                    showingSessions = false
                } label: {
                    Label("New Chat", systemImage: "square.and.pencil")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.accentColor)
                .listRowSeparator(.hidden)
            }
            
            Section {
                ForEach(dantaHistorySessions, id: \.key) { session in
                    Button {
                        viewModel.switchSession(to: session.key)
                        showingSessions = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sessionDisplayName(session))
                                    .font(.headline)
                                Text(session.key == DantaIntelligenceSession.newSessionKey ? "Draft" : "#\(session.key)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if session.key == viewModel.sessionKey {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
        }
        .listSectionSpacing(8)
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    showingSessions = false
                }
            }
        }
    }
    
    private var currentSessionLabel: String {
        DantaIntelligenceSession.isNew(viewModel.sessionKey) ? "New Chat" : "#\(viewModel.sessionKey)"
    }
    
    private var dantaHistorySessions: [OpenClawChatSessionEntry] {
        viewModel.sessions
            .filter { !DantaIntelligenceSession.isNew($0.key) }
            .sorted { ($0.updatedAt ?? 0) > ($1.updatedAt ?? 0) }
    }
    
    private func sessionDisplayName(_ session: OpenClawChatSessionEntry) -> String {
        if DantaIntelligenceSession.isNew(session.key) {
            return "New Chat"
        }
        return session.displayName ?? "Session"
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.smooth(duration: 0.25)) {
            if hasVisibleAssistantResponse(viewModel.streamingAssistantText) {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if viewModel.pendingRunCount > 0 {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let last = viewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
    
    private func hasVisibleAssistantResponse(_ text: String?) -> Bool {
        guard let text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return false
        }
        
        return DantaIntelligenceTextProcessing.assistantSegments(
            from: text,
            includeThinking: false
        ).contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

@available(iOS 18.0, *)
private struct DantaMessageBubble: View {
    let message: OpenClawChatMessage
    
    private var isUser: Bool {
        message.role.lowercased() == "user"
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            
            DantaMarkdownBubbleText(
                text: message.dantaPrimaryText,
                isUser: isUser)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isUser ? Color.white : Color.primary)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isUser ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            }
            
            if !isUser { Spacer(minLength: 48) }
        }
    }
}

@available(iOS 18.0, *)
private struct DantaStreamingBubble: View {
    let text: String
    
    var body: some View {
        HStack {
            DantaMarkdownBubbleText(text: text, isUser: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer(minLength: 48)
        }
    }
}

@available(iOS 18.0, *)
private struct DantaThinkingBubble: View {
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Thinking")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
            .accessibilityElement(children: .combine)
            
            Spacer(minLength: 48)
        }
    }
}

@available(iOS 18.0, *)
private struct DantaErrorBubble: View {
    let text: String
    
    var body: some View {
        HStack {
            Label(text, systemImage: "exclamationmark.triangle")
                .font(.callout)
                .foregroundStyle(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Spacer(minLength: 48)
        }
    }
}
