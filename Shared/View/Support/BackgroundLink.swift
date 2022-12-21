import SwiftUI

struct BackgroundLink<Destination: View>: ViewModifier {
    let destination: Destination
    
    func body(content: Content) -> some View {
        content
            .background(
                NavigationLink("", destination: destination)
                    .opacity(0)
            )
    }
}

struct BackgroundLinkActive<Destination: View>: ViewModifier {
    @Binding var active: Bool
    let destination: Destination
    
    func body(content: Content) -> some View {
        content
            .background(
                NavigationLink("", destination: destination, isActive: $active)
                    .opacity(0)
            )
    }
}

extension View {
    
    /// Invisible Navigation Link that can be activated programmatically.
    ///
    /// Usage:
    /// ```
    /// Text("Hello")
    ///     .backgroundLink($navActive) { navTarget }
    /// ```
    ///
    /// - Parameters:
    ///   - active: A binding to a Boolean value that indicates whether `destination` is currently presented.
    ///   - destination: A view for the navigation link to present.
    func backgroundLink<Destination: View>(_ active: Binding<Bool>,
                                           @ViewBuilder destination: () -> Destination) -> some View {
        modifier(BackgroundLinkActive(active: active,
                                      destination: destination()))
    }
    
    
    /// Invisible Navigation Link.
    ///
    /// Usage:
    /// ```
    /// Text("Hello")
    ///         .backgroundLink { navTarget }
    /// ```
    /// - Parameter destination: A view for the navigation link to present.
    func backgroundLink<Destination: View>(@ViewBuilder destination: () -> Destination) -> some View {
        modifier(BackgroundLink(destination: destination()))
    }
}
