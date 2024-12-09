import SwiftUI
import Combine

public class ForumNavigator: ObservableObject {
    public let forumFloor = PassthroughSubject<Int, Never>()
    public let forumHole = PassthroughSubject<Int, Never>()
    
    public init() { }
}
