import DanXiKit
import SwiftUI

@available(iOS 18.0, *)
struct DantaChatContent: View {
    @Bindable var viewModel: DantaChatViewModel
    var signIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            connectionBanner
            messageList
            composer
        }
    }

    @ViewBuilder
    private var connectionBanner: some View {
        if !viewModel.healthOK {
            Group {
                if isConnecting {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Connecting", bundle: .module)
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)
                } else {
                    HStack(spacing: 12) {
                        Label(
                            viewModel.connectionErrorText ?? String(localized: "Disconnected", bundle: .module),
                            systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            if viewModel.connectionRequiresLogin { signIn() }
                            else { viewModel.refresh() }
                        } label: {
                            Image(systemName: viewModel.connectionRequiresLogin ? "person.crop.circle" : "arrow.clockwise")
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text(viewModel.connectionRequiresLogin ? "Sign In Again" : "Refresh Conversation", bundle: .module))
                    }
                    .font(.callout)
                    .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .background(.bar)
        }
    }

    private var isConnecting: Bool {
        viewModel.isCheckingConnection || viewModel.isLoading
    }

    // Keep each failure for independent recovery, but present a shared connection failure once.
    private func inlineError(_ message: String?) -> String? {
        guard let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              viewModel.healthOK || message != viewModel.connectionErrorText else { return nil }
        return message
    }

    private var sendError: String? {
        guard let message = inlineError(viewModel.errorText),
              message != inlineError(viewModel.historyErrorText) else { return nil }
        return message
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 14) {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .padding(.top, 48)
                    }

                    ForEach(viewModel.messages) { message in
                        DantaMessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.pendingRunCount > 0 {
                        DantaThinkingBubble()
                            .id("thinking")
                    }

                    if let errorText = inlineError(viewModel.historyErrorText) {
                        DantaErrorNotice(message: errorText, retry: { viewModel.refresh() })
                    }

                    if let errorText = sendError {
                        DantaErrorNotice(message: errorText, retryTitle: "Refresh Conversation", retry: { viewModel.refresh() })
                            .id("error")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.vertical, 18)
            }
            .background(Color(.systemGroupedBackground))
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy)
            }
            .onChange(of: sendError) { _ in
                if sendError != nil { proxy.scrollTo("error", anchor: .bottom) }
            }
            .onChange(of: viewModel.pendingRunCount) { _ in
                scrollToBottom(proxy)
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                String(localized: "Ask Danta Intelligence", bundle: .module),
                text: $viewModel.input,
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
        .accessibilityLabel(Text("Send", bundle: .module))
        .disabled(!viewModel.canSend || !viewModel.healthOK)

        if #available(iOS 26.0, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.smooth(duration: 0.25)) {
            if viewModel.pendingRunCount > 0 {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let last = viewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

@available(iOS 18.0, *)
private struct DantaMessageBubble: View {
    let message: DantaIntelligenceMessage

    private var isUser: Bool {
        message.from.isUser
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            DantaMarkdownBubbleText(
                text: message.content,
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
private struct DantaThinkingBubble: View {
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Thinking", bundle: .module)
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
