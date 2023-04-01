import SwiftUI
import Disk

// TODO: A lot

@MainActor
class FDCalendarModel: ObservableObject {
    @Published var tables: [FDCourseTable] = []
    @Published var courses: [FDCourse] = []
    @Published var semesters: [FDSemester] = []
    @Published var baseDate: Date = Date.now
    @Published var weekStart: Date
    
    init() {
        let calendar = Calendar.current
        let today = Date.now
        let daysSinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
        dateComponents.day! -= daysSinceMonday
        weekStart = calendar.date(from: dateComponents)!
    }
    
    func load() async throws {
        if let bundle = try? Disk.retrieve("fdutools", from: .applicationSupport, as: FDCourseTableBundle.self) {
            self.tables = bundle.tables
            self.courses = bundle.tables[0].courses
            self.baseDate = bundle.baseDate
            return
        }
        
        try await FDAcademicAPI.login()
        semesters = try await FDAcademicAPI.getSemesters()
        courses = try await FDAcademicAPI.getCourseList()
    }
    
    func reload() async throws {
        
    }
}

struct FDCourseTableBundle: Codable {
    let tables: [FDCourseTable]
    let semesters: [FDSemester]
    let currentSemester: FDSemester
    let baseDate: Date
}
