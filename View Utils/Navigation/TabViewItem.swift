import SwiftUI
import Combine

public struct TabViewItem<Content: View, Label: View, Tag: Hashable>: View {
    @StateObject private var navigator = AppNavigator()
    
    private let tag: Tag
    private let content: () -> Content
    private let label: () -> Label
    
    public init(tag: Tag, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> Label) {
        self.tag = tag
        self.content = content
        self.label = label
    }
    
    public var body: some View {
        content()
            .tabItem { label() }
            .tag(tag)
            .environmentObject(navigator)
    }
}

public class TabViewModel: ObservableObject {
    /// User double-taps tab bar item. Navigation stack should pop to root.
    public let navigationControl = PassthroughSubject<Void, Never>()
    /// User double-taps tab bar item and the navigation stack is already empty, the view should scroll to top.
    public let scrollControl = PassthroughSubject<Void, Never>()
    
    public init() { }
}
