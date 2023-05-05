import SwiftUI

@MainActor
class THReportModel: ObservableObject {
    @Published var reports: [THReport] = []
    @Published var endReached = false
    
    func loadMoreReports() async throws {
        let newReports = try await THRequests.loadReports(offset: reports.count, range: filterOption.rawValue)
        endReached = newReports.isEmpty
        let ids = reports.map(\.id)
        reports += newReports.filter { !ids.contains($0.id) }
    }
    
    enum FilterOption: Int {
        case notDealt = 0
        case dealt = 1
        case all = 2
    }
    
    @Published var filterOption = FilterOption.notDealt {
        didSet {
            self.reports = []
        }
    }
    
    func markAsDealt(_ report: THReport) async {
        do {
            _ = try await THRequests.dealReport(reportId: report.id)
            
            if self.filterOption == .notDealt {
                if let idx = reports.firstIndex(of: report) {
                    reports.remove(at: idx)
                }
            }
        } catch {
            
        }
    }
}
