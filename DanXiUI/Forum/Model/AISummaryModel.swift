import SwiftUI
import Utils
import DanXiKit

@MainActor
class AISummaryModel: ObservableObject {
    enum LoadingState {
        case idle
        case loading
        case loaded(AISummaryContent, isGenerating: Bool)
        case error(Error)
    }
    
    @Published var state: LoadingState = .idle
    
    let hole: Hole
    
    init(hole: Hole) {
        self.hole = hole
    }
    
    func loadSummary() async {
        state = .loading
        do {
            while true {
                let response = try await ForumAPI.getAISummary(holeId: hole.id)
                switch response.code {
                case 1000:
                    guard let data = response.data else {
                        throw LocatableError("Invalid response")
                    }
                    state = .loaded(data, isGenerating: false)
                    return
                case 1001:
                    if let data = response.data {
                        state = .loaded(data, isGenerating: true)
                    }
                    break
                case 1002:
                    break
                case 2001:
                    throw LocatableError("Hole not found")
                case 2002:
                    throw LocatableError("Summary not available for this hole")
                case 3001:
                    throw LocatableError("Service error")
                default:
                    throw LocatableError("Unknown error")
                }
                try await Task.sleep(for: .seconds(0.5))
            }
        } catch {
            state = .error(error)
        }
    }
}
