import SwiftUI
import DanXiKit

@MainActor
class ReportModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var endReached = false
    @Published private(set) var configurationId = UUID()
    
    func insertReports(_ reports: [Report]) {
        endReached = reports.isEmpty
        let ids = self.reports.map(\.id)
        self.reports += reports.filter { !ids.contains($0.id) }
    }
    
    enum FilterOption: Int {
        case notDealt = 0
        case dealt = 1
        case all = 2
    }
    
    @Published var filterOption = FilterOption.notDealt {
        didSet {
            configurationId = UUID()
            endReached = false
            self.reports = []
        }
    }
    
    func loadMoreReports() async throws {
        let configurationId = self.configurationId
        let newReports = try await ForumAPI.listReports(offset: reports.count, type: filterOption.rawValue)
        try Task.checkCancellation()
        guard configurationId == self.configurationId else { return }
        insertReports(newReports)
    }
    
    func markAsDealt(_ report: Report) async {
        do {
            _ = try await ForumAPI.dealReport(id: report.id)
            
            if self.filterOption == .notDealt {
                if let idx = reports.firstIndex(of: report) {
                    Task { @MainActor in
                        reports.remove(at: idx)
                    }
                }
            }
        } catch {
            
        }
    }
}
