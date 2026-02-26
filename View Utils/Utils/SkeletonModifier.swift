import SwiftUI

public struct SkeletonModifier: ViewModifier {
    @State private var isPulsing = false
    
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .opacity(isPulsing ? 0.3 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

public extension View {
    func shimmeringPlaceholder() -> some View {
        modifier(SkeletonModifier())
    }
}
