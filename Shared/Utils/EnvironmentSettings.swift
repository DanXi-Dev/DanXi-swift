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

// MARK: - NavigationPath

class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
}

struct NavigationConfig: EnvironmentKey {
    static let defaultValue: NavigationRouter? = nil
}

extension EnvironmentValues {
    var navigation: NavigationRouter? {
        get { self[NavigationConfig.self] }
        set { self[NavigationConfig.self] = newValue }
    }
}

extension View {
    func navigation(_ router: NavigationRouter) -> some View {
        environment(\.navigation, router)
    }
}
