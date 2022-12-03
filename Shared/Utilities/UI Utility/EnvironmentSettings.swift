import SwiftUI

// MARK: - Preview Mode

struct PreviewMode: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var previewMode: Bool {
        get { self[PreviewMode.self] }
        set { self[PreviewMode.self] = newValue }
    }
}

extension View {
    func previewMode() -> some View {
        environment(\.previewMode, true)
    }
}

// MARK: - Interactable

struct Interactable: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var interactable: Bool {
        get { self[Interactable.self] }
        set { self[Interactable.self] = newValue }
    }
}

extension View {
    func interactable(_ config: Bool) -> some View {
        environment(\.interactable, config)
    }
}
