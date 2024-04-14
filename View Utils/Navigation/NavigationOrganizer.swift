import SwiftUI
import Combine

/// An organizer for navigation.
///  
/// This object is passed down the view hierarchy as environment object. Use this object
/// in deeply-nested views to manage global navigation status.
public class AppNavigator: ObservableObject {
    public typealias DetailNavigation = (any Hashable, Bool)
    
    /// A publisher for top-level view to receive content push event and append value to navigation path.
    public let contentSubject = PassthroughSubject<any Hashable, Never>()
    /// A publisher for top-level view to receive detail push event and append value to navigation path.
    /// The `Bool` parameter is to indicate whether it should clear the current detail navigation path.
    public let detailSubject = PassthroughSubject<DetailNavigation, Never>()
    /// Represent the screen width, whether it's compact.
    public let isCompactMode: Bool
    
    public init(isCompactMode: Bool) {
        self.isCompactMode = isCompactMode
    }
    
    /// Push a value into navigation stack in content column.
    ///
    /// This function pushes the value to the content column on wide screen. On smaller screen,
    /// this function simply pushes value into the current navigation stack.
    public func pushContent(value: any Hashable) {
        contentSubject.send(value)
    }
    
    /// Push a value into navigation stack in detail column.
    /// - Parameters:
    ///   - value: The value to be pushed into the navigation stack.
    ///   - replace: Whether to replace the current navigation path, or append it at the end of the current path.
    ///              This parameter has no effect on smaller screen.
    ///
    /// This function pushes the value to the detail column on wide screen. On smaller screen,
    /// this function simply pushes value into the current navigation stack.
    public func pushDetail(value: any Hashable, replace: Bool) {
        detailSubject.send((value, replace))
    }
}
