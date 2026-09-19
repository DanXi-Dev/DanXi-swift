import DanXiKit
import SwiftUI
import ViewUtils

@available(iOS 18.0, *)
public struct DantaIntelligencePage: View {
    @State private var model = DantaIntelligenceViewModel()
    @State private var sheet: Destination?

    private enum Destination: String, Identifiable {
        case sessions, instance
        var id: String { rawValue }
    }

    public init() { }

    public var body: some View {
        Group {
            if model.isReady {
                VStack(spacing: 0) {
                    if sheet == nil, let issue = displayedIssue {
                        DantaErrorNotice(issue: issue, isRetrying: model.isBusy || model.chat.isLoading) {
                            if issue.operation == .instance { await model.refreshInstanceStatus() }
                            else { model.chat.refresh() }
                        }
                        .padding(.horizontal)
                    }
                    DantaChatContent(viewModel: model.chat, showsConnectionProgress: displayedIssue == nil)
                }
            } else {
                preparationContent
            }
        }
        .navigationTitle(String(localized: "Danta Intelligence", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.isReady {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .sessions } label: { Image(systemName: "clock.arrow.circlepath") }
                        .accessibilityLabel(Text("Conversation History", bundle: .module))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { sheet = .instance } label: {
                    Image(systemName: "server.rack")
                }
                .accessibilityLabel(Text("Instance Management", bundle: .module))
            }
        }
        .sheet(item: $sheet) { destination in
            NavigationStack {
                switch destination {
                case .sessions:
                    DantaSessionList(chat: model.chat)
                case .instance:
                    DantaInstanceManagement(model: model)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .task { await model.refreshInstanceStatus() }
    }

    private var preparationContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: model.instanceState?.symbolName ?? "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(model.instanceState?.tintColor ?? .accentColor)
                Text(preparationTitle)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                if model.isBusy {
                    ProgressView()
                    Text("This may take a few minutes.", bundle: .module)
                        .foregroundStyle(.secondary)
                } else {
                    if sheet == nil {
                        if let issue = model.issue ?? model.previousInstanceIssue {
                            DantaErrorNotice(issue: issue) { await recoverInstance() }
                        } else {
                            recoveryAction
                        }
                    }
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 460)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .contentMargins(.top, 56)
        .background(Color(.systemGroupedBackground))
    }

    private var displayedIssue: DantaIntelligenceError? {
        if model.chat.issue?.requiresLogin == true { return model.chat.issue }
        return model.issue ?? model.chat.issue
    }

    private var preparationTitle: String {
        if case .lifecycle(let action) = model.operation { return action.progressTitle }
        switch model.phase {
        case .checking: return String(localized: "Checking Danta Intelligence", bundle: .module)
        case .preparing(.stopping): return DantaIntelligenceLifecycleAction.stop.progressTitle
        case .preparing(.resetting): return DantaIntelligenceLifecycleAction.reset.progressTitle
        case .preparing: return String(localized: "Preparing Danta Intelligence", bundle: .module)
        case .inactive(.notStarted): return String(localized: "Danta Intelligence is not set up", bundle: .module)
        case .inactive(.stopped): return String(localized: "Danta Intelligence is stopped", bundle: .module)
        case .inactive(.failed): return String(localized: "Danta Intelligence needs attention", bundle: .module)
        case .inactive: return String(localized: "Danta Intelligence is unavailable", bundle: .module)
        case .failed:
            if model.issue?.isReachabilityFailure == true {
                return String(localized: "Unable to connect to Danta Intelligence", bundle: .module)
            }
            return String(localized: "Unable to prepare Danta Intelligence", bundle: .module)
        case .ready: return String(localized: "Danta Intelligence is ready", bundle: .module)
        }
    }

    private var recoveryAction: some View {
        AsyncButton { await recoverInstance() } label: {
            Group {
                if let recoveryTitle {
                    Text(recoveryTitle, bundle: .module)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 44, height: 44)
                }
            }
        }
        .accessibilityLabel(Text(recoveryTitle ?? "Refresh Instance Status", bundle: .module))
        .buttonStyle(.borderedProminent)
    }

    private func recoverInstance() async {
        if model.issue != nil {
            await model.refreshInstanceStatus()
            return
        }
        switch model.instanceState {
        case .notStarted: await model.setup()
        case .stopped, .failed: await model.performLifecycleAction(.start)
        default: await model.refreshInstanceStatus()
        }
    }

    private var recoveryTitle: LocalizedStringKey? {
        switch model.instanceState {
        case .notStarted: "Enable Danta Intelligence"
        case .stopped, .failed: "Start Instance"
        default: nil
        }
    }
}

struct DantaErrorNotice: View {
    let issue: DantaIntelligenceError
    var isRetrying = false
    var retry: (() async -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Label(issue.localizedDescription, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !issue.requiresLogin, let retry {
                AsyncButton { await retry() } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("Retry", bundle: .module))
                .disabled(isRetrying)
                .buttonStyle(.borderless)
            }
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

@available(iOS 18.0, *)
struct DantaIntelligenceEntry: View {
    var body: some View {
        Section {
            NavigationLink(value: CommunitySection.dantaIntelligence) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .font(.title)
                    VStack(alignment: .leading) {
                        Text("Danta Intelligence", bundle: .module)
                            .font(.headline)
                        Text("Danta Intelligence Introduction", bundle: .module)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
}
