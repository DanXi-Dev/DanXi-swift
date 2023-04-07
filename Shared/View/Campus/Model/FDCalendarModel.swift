import Foundation
import Disk

@MainActor
class FDCalendarModel: ObservableObject {
    @Published var semester: FDSemester
    @Published var semesters: [FDSemester]
    var semesterUpdated = false
    @Published var semesterStart: Date? {
        didSet {
            reloadWeek()
        }
    }
    @Published var courses: [FDCourse]
    @Published var week: Int {
        didSet {
            reloadWeekStart()
        }
    }
    var weekRange: ClosedRange<Int> {
        if courses.isEmpty { return 1...1 }
        
        let (weekStart, weekEnd) = courses.reduce(into: (Int.max, Int.min)) {
            (result, course) in
            let (currentMin, currentMax) = course.weeks.reduce(into: (Int.max, Int.min)) {
                (result, element) in
                result = (min(result.0, element), max(result.1, element))
            }
            result = (min(result.0, currentMin), max(result.1, currentMax))
        }
        return weekStart...weekEnd
    }
    @Published var weekStart: Date?
    var expired: Bool {
        guard let semesterStart = self.semesterStart else { return false }
        let currentWeek = Self.getWeek(semesterStart)
        return currentWeek > self.weekRange.upperBound
    }
    var weekCourses: [FDCourse] {
        return courses.filter { course in
            course.openOn(week)
        }
    }
    
    
    static func load() async throws -> FDCalendarModel {
        // load from disk
        if let bundle = try? Disk.retrieve("fdutools/calendar.json", from: .applicationSupport, as: Bundle.self) {
            return FDCalendarModel(bundle)
        }
        
        // load from server
        try await FDAcademicAPI.login()
        let semesters = try await FDAcademicAPI.getSemesters()
        let (semesterId, courses) = try await FDAcademicAPI.getCourseList()
        let model = FDCalendarModel(semesters, semesterId, courses)
        try model.save()
        model.semesterUpdated = true
        return model
    }
    
    // MARK: - Load from Server
    
    init(_ semesters: [FDSemester],
         _ semesterId: Int,
         _ courses: [FDCourse]) {
        self.semesters = semesters
        self.semester = semesters.filter { $0.id == semesterId }.first!
        self.courses = courses
        
        self.week = 1
    }
    
    // MARK: - Load from Disk
    
    struct Bundle: Codable {
        let semester: FDSemester
        let semesters: [FDSemester]
        let semesterStart: Date?
        let courses: [FDCourse]
    }
    
    init(_ bundle: Bundle) {
        self.semester = bundle.semester
        self.semesters = bundle.semesters
        self.semesterStart = bundle.semesterStart
        self.courses = bundle.courses
        self.week = 1

        reloadWeek()
        reloadWeekStart()
    }
    
    func save() throws {
        let bundle = Bundle(semester: semester, semesters: semesters, semesterStart: semesterStart, courses: courses)
        try Disk.save(bundle, to: .applicationSupport, as: "fdutools/calendar.json")
    }
    
    // MARK: - Time
    
    static func getWeekStart() -> Date {
        let calendar = Calendar.current
        let today = Date.now
        let daysSinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
        dateComponents.day! -= daysSinceMonday
        return calendar.date(from: dateComponents)!
    }
    
    static func getWeek(_ startDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: startDate, to: Date.now)
        let weeks = (components.weekOfYear ?? 0) + 1
        return weeks
    }
    
    private func reloadWeek() {
        if let semesterStart = self.semesterStart {
            let week = Self.getWeek(semesterStart)
            let weekRange = self.weekRange
            if week < weekRange.lowerBound {
                self.week = weekRange.lowerBound
            } else if week > weekRange.upperBound {
                self.week = weekRange.upperBound
            } else {
                self.week = week
            }
        }
    }
    
    private func reloadWeekStart() {
        if let semesterStart = self.semesterStart {
            let calendar = Calendar.current
            let dateComponents = DateComponents(weekOfYear: week - 1)
            self.weekStart = calendar.date(byAdding: dateComponents, to: semesterStart)
        }
    }
    
    // MARK: - Utility
    
    func reloadSemesters() async throws {
        if semesterUpdated { return }
        try await FDAcademicAPI.login()
        semesters = try await FDAcademicAPI.getSemesters()
        semesterUpdated = true
    }
    
    func refresh(_ semester: FDSemester) async throws {
        if semester.id == self.semester.id { // only set date, no need to request from server
            try save()
            return
        }
        
        // request from server
        try await FDAcademicAPI.login()
        (_, self.courses) = try await FDAcademicAPI.getCourseList(semester: semester.id)
        self.semester = semester
        try save()
    }
}
