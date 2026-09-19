import DanXiKit
import SwiftUI

@available(iOS 18.0, *)
struct DantaChatContent: View {
    @Bindable var viewModel: DantaChatViewModel
    var showsConnectionProgress = true

    var body: some View {
        VStack(spacing: 0) {
            if showsConnectionProgress, !viewModel.healthOK,
               viewModel.isCheckingConnection || viewModel.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Connecting", bundle: .module)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .background(.bar)
                .accessibilityElement(children: .combine)
            }
            messageList
            composer
        }
    }

    @ViewBuilder
    private var messageList: some View {
        if viewModel.messages.isEmpty, viewModel.pendingRunCount == 0 {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            } else {
                emptyPlaceholder
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(viewModel.messages) { message in
                            DantaMessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.pendingRunCount > 0 {
                            DantaThinkingBubble()
                                .id("thinking")
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
                .onChange(of: viewModel.pendingRunCount) { _ in
                    scrollToBottom(proxy)
                }
            }
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("No messages yet.", bundle: .module)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
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
                .onKeyPress(.return, phases: .down) { press in
                    guard press.modifiers.contains(.control) else { return .ignored }
                    viewModel.send()
                    return .handled
                }

            sendButton
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                // Cover the area exposed by the keyboard's rounded corners.
                .ignoresSafeArea(.all, edges: .bottom)
        }
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
