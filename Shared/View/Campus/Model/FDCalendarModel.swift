import Foundation
import EventKit
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
    
    
    func exportToCalendar(_ calendar: EKCalendar) {
        guard let base = semesterStart else { return }
        
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { granted, error in
            guard granted, error == nil else {
                return
            }
            
            for course in self.courses {
                do {
                    if course.weeks.isEmpty { continue }
                    
                    if let recurrentWeek = course.recurrentWeek {
                        let event = EKEvent(eventStore: eventStore)
                        event.title = course.name
                        event.location = course.location
                        (event.startDate, event.endDate) = course.calcTime(base: base, week: course.weeks.first!)
                        let recurrenceRule = EKRecurrenceRule(
                            recurrenceWith: .weekly,
                            interval: recurrentWeek,
                            end: EKRecurrenceEnd(occurrenceCount: (course.weeks.last! - course.weeks.first!) / recurrentWeek + 1)
                        )
                        event.addRecurrenceRule(recurrenceRule)
                        event.calendar = calendar
                        try eventStore.save(event, span: .thisEvent, commit: false)
                    } else {
                        for week in course.weeks {
                            let event = EKEvent(eventStore: eventStore)
                            event.title = course.name
                            event.location = course.location
                            (event.startDate, event.endDate) = course.calcTime(base: base, week: week)
                            event.calendar = calendar
                            try eventStore.save(event, span: .thisEvent, commit: false)
                        }
                    }
                } catch {
                    continue
                }
            }
            
            do {
                try eventStore.commit()
            } catch {
                
            }
        }
    }
}

extension FDCourse {
    var weekly: Bool {
        guard let max = weeks.max(), let min = weeks.min() else {
            return false
        }
        return (max - min) == (weeks.count - 1)
    }
    
    var doubleWeekly: Bool {
        guard weeks.count > 1 else { return false }
        for i in 1..<weeks.count {
            if weeks[i] - weeks[i - 1] != 2 { return false }
        }
        return true
    }
    
    var recurrentWeek: Int? {
        if weekly { return 1 }
        if doubleWeekly { return 2 }
        return nil
    }
    
    func calcTime(base: Date, week: Int) -> (Date, Date) {
        let calendar = Calendar.current
        let days = week * 7 + weekday
        let day = calendar.date(byAdding: DateComponents(day: days), to: base)!
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        
        let startComponent = FDTimeSlot.getItem(start + 1)
        components.hour = startComponent.startTime.hour
        components.minute = startComponent.startTime.minute
        let startDate = calendar.date(from: components)!
        
        let endComponent = FDTimeSlot.getItem(end + 1)
        components.hour = endComponent.endTime.hour
        components.minute = endComponent.endTime.minute
        let endDate = calendar.date(from: components)!
        
        return (startDate, endDate)
    }
}
