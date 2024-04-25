import SwiftUI

// ref: https://www.swiftbysundell.com/articles/building-an-async-swiftui-button/
public struct AsyncButton<Label: View>: View {
    private var actionOptions: Set<ActionOption> = [.disableButton]
    private var action: () async throws -> Void
    @ViewBuilder private var label: () -> Label
    
    public init(actionOptions: Set<ActionOption> = [.disableButton],
                action: @escaping () async throws -> Void,
                label: @escaping () -> Label) {
        self.actionOptions = actionOptions
        self.action = action
        self.label = label
    }
    
    @State private var isDisabled = false
    @State private var showProgressView = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    public var body: some View {
        Button(
            action: {
                if actionOptions.contains(.disableButton) {
                    isDisabled = true
                }
                
                Task {
                    do {
                        defer {
                            isDisabled = false
                            showProgressView = false
                        }
                        
                        var progressViewTask: Task<Void, Error>?
                        
                        if actionOptions.contains(.showProgressView) {
                            progressViewTask = Task {
                                try await Task.sleep(nanoseconds: 150_000_000)
                                showProgressView = true
                            }
                        }
                        
                        try await action()
                        progressViewTask?.cancel()
                    } catch {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            },
            label: {
                ZStack {
                    label().opacity(showProgressView ? 0 : 1)
                    
                    if showProgressView {
                        ProgressView()
                    }
                }
            }
        )
        .disabled(isDisabled)
        .alert(alertMessage, isPresented: $showAlert) { }
    }
}

extension AsyncButton {
    public enum ActionOption: CaseIterable {
        case disableButton
        case showProgressView
    }
}

extension AsyncButton where Label == Text {
    public init(_ label: String,
                actionOptions: Set<ActionOption> = [.disableButton],
                action: @escaping () async throws -> Void) {
        self.init(action: action) {
            Text(label)
        }
    }
}

extension AsyncButton where Label == Image {
    init(systemImageName: String,
         actionOptions: Set<ActionOption> = [.disableButton],
         action: @escaping () async throws -> Void) {
        self.init(action: action) {
            Image(systemName: systemImageName)
        }
    }
}
