import SwiftUI

/// A replacement for ``NavigationLink`` that pushes value into content column or
/// simply the current stack, depending on the screen width.
public struct ContentLink<Label: View, Value: Hashable>: View {
    @EnvironmentObject private var organizer: AppNavigator
    private let label: Label
    private let value: Value
    
    
    /// Creates a content link.
    /// - Parameters:
    ///   - value: The value for value-based navigation.
    ///   - label: The label of link.
    public init(value: Value, @ViewBuilder label: () -> Label) {
        self.value = value
        self.label = label()
    }
    
    public var body: some View {
        Button {
            organizer.pushContent(value: value)
        } label: {
            label
        }
    }
}


/// A replacement for ``NavigationLink`` that pushes value into detail column or
/// simply the current stack, depending on the screen width.
public struct DetailLink<Label: View, Value: Hashable>: View {
    @EnvironmentObject private var organizer: AppNavigator
    private let label: Label
    private let value: Value
    private let replace: Bool
    
    
    /// Creates a detail link.
    /// - Parameters:
    ///   - value: The value for value-based navigation.
    ///   - replace: Whether to replace the detail navigation path, or simply append to it. This parameter
    ///              has no effect on smaller screen.
    ///   - label: The label of link.
    public init(value: Value, replace: Bool = true, @ViewBuilder label: () -> Label) {
        self.value = value
        self.replace = replace
        self.label = label()
    }
    
    public var body: some View {
        Button {
            organizer.pushDetail(value: value, replace: replace)
        } label: {
            label
        }
    }
}
