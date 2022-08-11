import Foundation

@MainActor
class TreeholeViewModel: ObservableObject {
    @Published var currentDivision = THDivision.dummy
    @Published var currentDivisionId = 1
    @Published var holes: [THHole] = []
    @Published var errorPresenting = false
    @Published var errorInfo = ErrorInfo()
    
    func initialLoad() async { // FIXME: SwiftUI bug, .task modifier might be executed twice, causing NSURLErrorCancelled
        guard treeholeDataModel.divisions.isEmpty else { // prevent duplicate loading
            return
        }
        
        do {
            let divisions = try await networks.loadDivisions()
            currentDivision = divisions[0]
            treeholeDataModel.divisions = divisions
            Task {
                await loadMoreHoles()
            }
        } catch let error as NetworkError {
            self.errorInfo = error.localizedErrorDescription
            errorPresenting = true
        } catch {
            print("DANXI-DEBUG: initial load failed, error: \(error)")
        }
    }
    
    func loadMoreHoles() async {
        do {
            let newHoles = try await networks.loadHoles(startTime: holes.last?.iso8601UpdateTime, divisionId: currentDivision.id)
            holes.append(contentsOf: newHoles)
        } catch let error as NetworkError {
            self.errorInfo = error.localizedErrorDescription
            errorPresenting = true
        } catch {
            print("DANXI-DEBUG: load more holes failed, error: \(error)")
        }
    }
    
    func changeDivision(division: THDivision) async {
        holes = []
        currentDivision = division
        await loadMoreHoles()
    }
    
    func refresh() async {
        holes = []
        await loadMoreHoles()
    }
}
