import SwiftUI
import Combine

public class CampusNavigator: ObservableObject {
    public let campusSection = PassthroughSubject<String, Never>()
    
    public init() { }
}
