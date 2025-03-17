import DanXiKit
import SwiftUI

/// A modifier that executes a specified action when a view disappears or the app transitions to the background.
struct OnDisappearOrBackground: ViewModifier {
    /// The current scene phase of the environment.
    @Environment(\.scenePhase) private var scenePhase
    let action: () -> Void
    func body(content: Content) -> some View {
        content
            .onDisappear(perform: action)
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background {
                    action()
                }
            }
    }
}

extension View {
    func onDisappearOrBackground(action: @escaping () -> Void) -> some View {
        modifier(OnDisappearOrBackground(action: action))
    }
}
