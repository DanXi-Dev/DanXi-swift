import SwiftUI

@MainActor
class THReportModel: ObservableObject {
    @Published var reports: [THReport] = []
    @Published var loading = false
    @Published var endReached = false
    @Published var loadingError: Error?
    
    func loadMoreReports() async {
        do {
            loading = true
            defer { loading = false }
            let newReports = try await THRequests.loadReports(offset: reports.count, range: filterOption.rawValue)
            endReached = newReports.isEmpty
            let ids = reports.map(\.id)
            let filteredReports = newReports.filter { !ids.contains($0.id) }
            reports.append(contentsOf: filteredReports)
        } catch {
            loadingError = error
        }
    }
    
    enum FilterOption: Int {
        case notDealt = 0
        case dealt = 1
        case all = 2
    }
    
    @Published var filterOption = FilterOption.notDealt {
        didSet {
            Task {
                self.reports = []
                await loadMoreReports()
            }
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
