import Foundation

@MainActor
class TreeholeViewModel: ObservableObject {
    @Published var currentDivision = THDivision.dummy
    @Published var currentDivisionId = 1
    @Published var holes: [THHole] = []
    @Published var errorPresenting = false
    @Published var errorInfo = ErrorInfo()
    @Published var sortByReplyTime: Bool = true
    
    func initialLoad() async { // FIXME: SwiftUI bug, .task modifier might be executed twice, causing NSURLErrorCancelled
        guard TreeholeDataModel.shared.divisions.isEmpty else { // prevent duplicate loading
            return
        }
        
        do {
            let divisions = try await NetworkRequests.shared.loadDivisions()
            currentDivision = divisions[0]
            TreeholeDataModel.shared.divisions = divisions
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
            let startTime = sortByReplyTime ? holes.last?.iso8601UpdateTime : holes.last?.iso8601CreateTime // FIXME: first batch of holes not sorted
            let newHoles = try await NetworkRequests.shared.loadHoles(startTime: startTime, divisionId: currentDivision.id)
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
    
    func switchSortOption(sortByReplyTime: Bool) async {
        if self.sortByReplyTime == sortByReplyTime {
            return
        }
        
        self.sortByReplyTime = sortByReplyTime
        holes = []
        await loadMoreHoles()
    }
}
