import SwiftUI
import DanXiKit

class DivisionStore: ObservableObject {
    static let shared = DivisionStore()
    
    @Published var divisions: [Division] = []
    var initialized = false
    
    @MainActor
    private func set(divisions: [Division]) {
        self.divisions = divisions
    }
    
    func refreshDivisions() async throws {
        let divisions = try await ForumAPI.getDivisions()
        await set(divisions: divisions)
        initialized = true
    }
}
