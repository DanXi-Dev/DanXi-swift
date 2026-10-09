import DanXiKit
import SwiftUI
import ViewUtils

@available(iOS 18.0, *)
struct DantaInstanceManagement: View {
    let model: DantaIntelligenceViewModel
    @State private var confirmingReset = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        List {
            Section {
                statusRow
                if model.isBusy {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(progressTitle)
                            .foregroundStyle(.secondary)
                    }
                }
                if let id = model.instanceStatus?.instanceId {
                    detailRow(String(localized: "Instance ID", bundle: .module), value: "#\(id)")
                }
            }

            if let issue = model.issue {
                Section {
                    DantaErrorNotice(issue: issue)
                }
            } else if let issue = model.previousInstanceIssue {
                Section {
                    Text(issue.localizedDescription)
                        .foregroundStyle(.secondary)
                } header: { Text("Last Reported Issue", bundle: .module) }
            }

            Section {
                ForEach([DantaIntelligenceLifecycleAction.start, .stop, .restart], id: \.self) { action in
                    if model.canPerform(action) {
                        AsyncButton { await model.performLifecycleAction(action) } label: {
                            Label(action.buttonTitle, systemImage: action.symbolName)
                        }
                    }
                }
                if model.canPerform(.reset) {
                    Button(role: .destructive) { confirmingReset = true } label: {
                        Label { Text("Reset Instance", bundle: .module) } icon: { Image(systemName: "trash") }
                            .foregroundStyle(.red)
                    }
                    .tint(.red)
                    .confirmationDialog(String(localized: "Reset OpenClaw Instance?", bundle: .module),
                                        isPresented: $confirmingReset, titleVisibility: .visible) {
                        Button(role: .destructive) {
                            Task { await model.performLifecycleAction(.reset) }
                        } label: { Text("Reset Instance", bundle: .module) }
                        Button(role: .cancel) { } label: { Text("Cancel", bundle: .module) }
                    } message: {
                        Text("This permanently deletes the instance, all messages, and all conversations. This action cannot be undone.", bundle: .module)
                    }
                }
            } footer: {
                if showsActionButtons {
                    Text("Stopping preserves your instance data and chats. Resetting permanently deletes them.", bundle: .module)
                }
            }
        }
        .navigationTitle(String(localized: "Instance Management", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                refreshButton
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { dismiss() } label: { Text("Done", bundle: .module) }
            }
        }
        .refreshable { await model.refreshInstanceStatus() }
    }

    private var statusRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Text("Status", bundle: .module)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 12) }
            Label(model.instanceState?.displayName ?? String(localized: "Unknown", bundle: .module),
                  systemImage: model.instanceState?.symbolName ?? "questionmark.circle")
                .foregroundStyle(model.instanceState?.tintColor ?? .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var refreshButton: some View {
        AsyncButton { await model.refreshInstanceStatus() } label: {
            Image(systemName: "arrow.clockwise")
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(Text("Refresh Instance Status", bundle: .module))
        .disabled(model.isBusy)
    }

    private var showsActionButtons: Bool {
        [DantaIntelligenceLifecycleAction.start, .stop, .restart].contains { model.canPerform($0) }
            || model.canPerform(.reset)
    }

    private var progressTitle: String {
        switch model.operation {
        case .lifecycle(let action): action.progressTitle
        case .setup: String(localized: "Preparing instance…", bundle: .module)
        default: String(localized: "Checking Danta Intelligence", bundle: .module)
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer(minLength: 12)
            Text(value).foregroundStyle(.secondary)
        }
    }
}
