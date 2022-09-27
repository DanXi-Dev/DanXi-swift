import SwiftUI

struct LoadingOverlay: ViewModifier {
    let loading: Bool
    let prompt: LocalizedStringKey
    
    func body(content: Content) -> some View {
        content
            .overlay(
                HStack(alignment: .center, spacing: 20) {
                    ProgressView()
                    Text(prompt)
                        .foregroundColor(.secondary)
                        .bold()
                }
                    .padding(35)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .animation(.easeInOut, value: loading)
                    .opacity(loading ? 1 : 0)
            )
            .ignoresSafeArea(.keyboard) // prevent keyboard from pushing up loading overlay
    }
}

extension View {
    /// Add a material overlay to the page when performing loading action.
    /// - Parameters:
    ///   - loading: Determine whether the overlay is visible.
    ///   - prompt: Displayed text.
    func loadingOverlay(loading: Bool,
                        prompt: LocalizedStringKey = "Submitting...") -> some View {
        modifier(LoadingOverlay(loading: loading, prompt: prompt))
    }
}
