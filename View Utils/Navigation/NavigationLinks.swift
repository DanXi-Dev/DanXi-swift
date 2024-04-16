import SwiftUI

/// A replacement for ``NavigationLink`` that pushes value into content column or
/// simply the current stack, depending on the screen width.
public struct ContentLink<Label: View, Value: Hashable>: View {
    @EnvironmentObject private var navigator: AppNavigator
    private let label: Label
    private let action: () -> Void
    private let value: Value
    
    
    /// Creates a content link.
    /// - Parameters:
    ///   - value: The value for value-based navigation.
    ///   - action: Logic to be executed before performing navigation.
    ///   - label: The label of link.
    public init(value: Value, action: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        self.value = value
        self.action = action
        self.label = label()
    }
    
    public var body: some View {
        Button {
            action()
            navigator.pushContent(value: value)
        } label: {
            label
        }
    }
}


/// A replacement for ``NavigationLink`` that pushes value into detail column or
/// simply the current stack, depending on the screen width.
public struct DetailLink<Label: View, Value: Hashable>: View {
    @EnvironmentObject private var navigator: AppNavigator
    private let label: Label
    private let value: Value
    private let action: () -> Void
    private let replace: Bool
    
    
    /// Creates a detail link.
    /// - Parameters:
    ///   - value: The value for value-based navigation.
    ///   - replace: Whether to replace the detail navigation path, or simply append to it. This parameter
    ///              has no effect on smaller screen.
    ///   - action: Logic to be executed before performing navigation.
    ///   - label: The label of link.
    public init(value: Value, replace: Bool = true, action: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        self.value = value
        self.replace = replace
        self.action = action
        self.label = label()
    }
    
    public var body: some View {
        Button {
            action()
            navigator.pushDetail(value: value, replace: replace)
        } label: {
            label
        }
    }
}

struct NavigationModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
        .tint(.primary)
    }
}

extension View {
    /// Add a cheveron to button-based navigation link.
    public func navigationStyle() -> some View {
        self.modifier(NavigationModifier())
    }
}
