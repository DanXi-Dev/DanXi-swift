import Foundation
import SwiftUI

@MainActor
class TreeholeViewModel: ObservableObject {
    @Published var currentDivision = THDivision.dummy
    @Published var currentDivisionId = 1
    @Published var holes: [THHole] = []
    
    @Published var sortOption = SortOptions.byReplyTime
    
    @Published var initLoading = true
    @Published var initFailed = false
    @Published var initError = ErrorInfo()
    
    enum SortOptions {
        case byReplyTime
        case byCreateTime
    }
    
    func initialLoad() async { // FIXME: SwiftUI bug, .task modifier might be executed twice, causing NSURLErrorCancelled
        guard TreeholeDataModel.shared.divisions.isEmpty else { // prevent duplicate loading
            return
        }
        
        do {
            let divisions = try await NetworkRequests.shared.loadDivisions()
            currentDivision = divisions[0]
            TreeholeDataModel.shared.divisions = divisions
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            initFailed = true
            initError = error.localizedErrorDescription
        } catch {
            initFailed = true
            initError = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
        }
    }
    
    func loadMoreHoles() async {
        do {
            let startTime = sortOption == .byReplyTime ? holes.last?.updateTime.ISO8601Format() : holes.last?.createTime.ISO8601Format() // FIXME: first batch of holes not sorted // FIXME: first batch of holes not sorted
            let newHoles = try await NetworkRequests.shared.loadHoles(startTime: startTime, divisionId: currentDivision.id)
            holes.append(contentsOf: newHoles)
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            // TODO: deal with this error
            print("DANXI-DEBUG: load more holes failed, error: \(error)")
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
    
    func switchSortOption(_ sortOption: SortOptions) async {
        // TODO: This preference should be remembered
        self.sortOption = sortOption
        holes = []
        await loadMoreHoles()
    }
}
