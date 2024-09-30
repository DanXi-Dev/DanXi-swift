import SwiftUI
#if !os(watchOS)
import EventKit
import Disk
#else
import Utils
#endif

public class CourseModel: ObservableObject {
    
    // MARK: - Factory Methods
    
    /// Factory constructor for graduate student to create a new model from network
    /// - Returns: A new model loaded from network
    public static func freshLoadForGraduate() async throws -> CourseModel {
        let (semesters, currentSemesterFromServer) = try await GraduateCourseStore.shared.getRefreshedSemesters()
        guard !semesters.isEmpty else { throw URLError(.badServerResponse) }
        let currentSemester = currentSemesterFromServer ?? semesters.last! // this force unwrap cannot fail, as semesters is checked to be not empty.
        let courses = try await GraduateCourseStore.shared.getRefreshedCourses(semester: currentSemester)
        let week = computeWeekOffset(from: currentSemester.startDate, courses: courses)
        let model = CourseModel(studentType: .grad, courses: courses, semester: currentSemester, semesters: semesters, week: week)
        model.refreshCache()
        return model
    }
    
    /// Factory constructor for undergraduate student to create a new model from network
    /// - Parameter startDateContext: the start date configuration that maps a semester ID to it's start date. This should be retrieved from DanXi backend.
    /// - Returns: A new model loaded from network
    public static func freshLoadForUndergraduate(startDateContext: [Int: Date]) async throws -> CourseModel {
        var (semesters, currentSemesterFromServer) = try await UndergraduateCourseStore.shared.getRefreshedSemesters()
        guard !semesters.isEmpty else { throw URLError(.badServerResponse) }
        var currentSemester = currentSemesterFromServer ?? semesters.last! // this force unwrap cannot fail, as semesters is checked to be not empty.
        
        // match semester start date
        semesters = matchUndergraduateSemesterStartDateByContext(semesters: semesters, context: startDateContext)
        currentSemester.startDate = startDateContext[currentSemester.semesterId]
        
        let courses = try await UndergraduateCourseStore.shared.getRefreshedCourses(semester: currentSemester)
        let startDate = startDateContext[currentSemester.semesterId]
        let week = computeWeekOffset(from: startDate, courses: courses)
        let model = CourseModel(studentType: .undergrad, courses: courses, semester: currentSemester, semesters: semesters, week: week)
        model.refreshCache()
        return model
    }
    
    /// Factory constructor for recreatng a model from local cache
    /// - Parameter studentType: the type of the student. If it's not matched with cache, it will return `nil` and invalidate cache.
    /// - Returns: A model recreated from local cache
    public static func loadCache(for studentType: StudentType) throws -> CourseModel? {
        guard let cache = try? Disk.retrieve("fdutools/course-model.json", from: .appGroup, as: CourseModelCache.self) else {
            return nil
        }
        
        guard cache.studentType == studentType else {
            Task(priority: .background) {
                try Disk.remove("fdutools/course-model.json", from: .appGroup)
            }
            return nil
        }
        
        let week = computeWeekOffset(from: cache.semester.startDate, courses: cache.courses)
        return CourseModel(cache: cache, week: week)
    }
    
    // MARK: - Initializers
    
    init(studentType: StudentType, courses: [Course], semester: Semester, semesters: [Semester], week: Int) {
        self.studentType = studentType
        self.courses = courses
        self.semester = semester
        self.semesters = semesters
        self.week = week
    }
    
    init(cache: CourseModelCache, week: Int) {
        self.studentType = cache.studentType
        self.courses = cache.courses
        self.semester = cache.semester
        self.semesters = cache.semesters
        self.week = week
    }
    
    // MARK: - Source of Truth
    
    let studentType: StudentType
    @Published public var courses: [Course]
    @Published public var semester: Semester
    @Published public var semesters: [Semester]
    @Published public var week: Int
    @Published public var networkError: Error? = nil
    
    // MARK: - Computed Property
    
    public var filteredSemsters: [Semester] {
        let currentYear = Calendar.current.component(.year, from: Date())
        
        var filtered = semesters.filter({ $0.year > currentYear - 5 && $0.year <= currentYear })
        if !filtered.contains(where: { $0 == semester }) {
            filtered.append(semester)
        }
        
        return filtered.sorted()
    }
    
    public var weekRange: ClosedRange<Int> {
        if let max = courses.compactMap({ $0.onWeeks.max() }).max(),
           let min = courses.compactMap({ $0.onWeeks.min() }).min() {
            return min...max
        }
        
        return 1...1
    }
    
    public var weekStart: Date? {
        guard let semesterStartDate = self.semester.startDate else {
            return nil
        }
        let calendar = Calendar.current
        let dateComponents = DateComponents(weekOfYear: week - 1)
        return calendar.date(byAdding: dateComponents, to: semesterStartDate)
    }
    
    public var coursesInThisWeek: [Course] {
        courses.filter { course in
            course.onWeeks.contains(week)
        }
    }
    
    // MARK: - Model Update
    
    /// Work to be done after semester is changed
    @MainActor public func updateSemester() async {
        courses = []
        do {
            if studentType == .undergrad {
                courses = try await UndergraduateCourseStore.shared.getCachedCourses(semester: semester)
            } else if studentType == .grad {
                courses = try await GraduateCourseStore.shared.getCachedCourses(semester: semester)
            }
            refreshCache()
        } catch {
            networkError = error
        }
    }
    
    
    /// Refresh courses in current semester and refresh semesters list
    /// - Parameter context: A context for undergraduate student to match semester start date. It should be retrieved from DanXi backend.
    @MainActor public func refresh(with context: [Int: Date]) async {
        do {
            if studentType == .undergrad {
                courses = try await UndergraduateCourseStore.shared.getRefreshedCourses(semester: semester)
                let (semesters, currentSemester) = try await UndergraduateCourseStore.shared.getRefreshedSemesters()
                guard semesters.isEmpty else {
                    throw URLError(.badServerResponse)
                }
                self.semesters = matchUndergraduateSemesterStartDateByContext(semesters: semesters, context: context)
                if self.semesters.contains(semester) {
                    semester = currentSemester ?? semesters.last! // force unwrap is safe as semesters is checked not empty
                }
            } else if studentType == .grad {
                courses = try await GraduateCourseStore.shared.getRefreshedCourses(semester: semester)
                let (semesters, currentSemester) = try await GraduateCourseStore.shared.getRefreshedSemesters()
                guard semesters.isEmpty else {
                    throw URLError(.badServerResponse)
                }
                self.semesters = semesters
                if self.semesters.contains(semester) {
                    semester = currentSemester ?? semesters.last! // force unwrap is safe as semesters is checked not empty
                }
            }
            
            refreshCache()
        } catch {
            networkError = error
        }
    }
    
    /// The semester start date received from server might be incorrect. This method support user to manually set the start date.
    public func manualResetSemesterStartDate(startDate: Date) {
        semester.startDate = startDate
        guard let idx = semesters.firstIndex(of: semester) else { return }
        semesters[idx].startDate = startDate
        refreshCache()
    }
    
    
    /// This is for undergraduate student to update semester start date when context change.
    /// - Parameter startDateContext: A context for undergraduate student to match semester start date. It should be retrieved from DanXi backend.
    public func receiveUndergraduateStartDateContextUpdate(startDateContext: [Int: Date]) {
        guard studentType == .undergrad else { return }
        semesters = matchUndergraduateSemesterStartDateByContext(semesters: semesters, context: startDateContext)
        semester.startDate = startDateContext[semester.semesterId]
        refreshCache()
    }
    
    /// An internal method that persists data to disk when model updates.
    func refreshCache() {
        Task(priority: .background) {
            let cache = CourseModelCache(studentType: studentType, courses: courses, semester: semester, semesters: semesters)
            try Disk.save(cache, to: .appGroup, as: "fdutools/course-model.json")
        }
    }
    
    // MARK: - Calendars
    
    #if !os(watchOS)
    
    public struct CourseKey: Identifiable, Hashable {
        public var id: String { code }
        public let code: String
        public let name: String
    }
    
    /// The courses retrieved from server are separated.
    /// To create a unified selection page, distinct courses with same ID should be grouped by the same key.
    public var calendarMap: [CourseKey: [Course]] {
        var map: [CourseKey: [Course]] = [:]
        
        for course in courses {
            let key = CourseKey(code: course.code, name: course.name)
            map[key, default: []].append(course)
        }
        
        return map
    }
    
    public func exportToCalendar(to calendar: EKCalendar, keys: Set<CourseKey>, eventStore: EKEventStore) throws {
        guard let startDate = semester.startDate else { return }
        
        for key in keys {
            guard let courses = self.calendarMap[key] else { continue }
            for course in courses {
                try course.exportEvents(for: eventStore, to: calendar, semesterStart: startDate)
            }
        }
        
        try eventStore.commit()
    }
    
    #endif
}

func computeWeekOffset(from startDate: Date?, courses: [Course]) -> Int {
    let max = courses.compactMap({ $0.onWeeks.max() }).max() ?? 1
    let min = courses.compactMap({ $0.onWeeks.min() }).min() ?? 1
    
    guard let startDate = startDate else { return min }
    
    let calendar = Calendar.current
    let components = calendar.dateComponents([.weekOfYear], from: startDate, to: Date.now)
    let weeks = (components.weekOfYear ?? 0) + 1
    
    if weeks < min {
        return min
    }
    if weeks > max {
        return max
    }
    return weeks
}


/// The undergraduate course API returns semesters with no start date information,
/// it should be matched with context provided by DanXi-static to fill this value.
/// - Parameters:
///   - semesters: semesters
///   - context: the start date configuration that maps a semester ID to it's start date. This should be retrieved from DanXi backend.
/// - Returns: A list of updated semesters.
func matchUndergraduateSemesterStartDateByContext(semesters: [Semester], context: [Int: Date]) -> [Semester] {
    return semesters.map { semester in
        var updatedSemester = semester
        if let startDate = context[semester.semesterId] {
            updatedSemester.startDate = startDate
        }
        return updatedSemester
    }
}

struct CourseModelCache: Codable {
    let studentType: StudentType
    let courses: [Course]
    let semester: Semester
    let semesters: [Semester]
}

// MARK: - Extension to Course for Calendar Export

extension Course {
    /// Determine whether the course is recurrent on every week
    var weekly: Bool {
        guard let max = onWeeks.max(), let min = onWeeks.min() else { return false }
        return (max - min) == (onWeeks.count - 1)
    }
    
    /// Determine whether the course is recurrent every two week
    var doubleWeekly: Bool {
        guard onWeeks.count > 1 else { return false }
        for i in 1..<onWeeks.count {
            if onWeeks[i] - onWeeks[i - 1] != 2 { return false }
        }
        return true
    }
    
    /// For `EKRecurrenceRule`'s `interval` param
    var recurrentWeek: Int? {
        if weekly { return 1 }
        if doubleWeekly { return 2 }
        return nil
    }
    
    /// Compute the actual start time and end time of a course on a given week, with respect to `semesterStart`.
    func computeTime(from semesterStart: Date, on week: Int) -> (Date, Date) {
        let calendar = Calendar.current
        let timeZone = TimeZone(identifier: "Asia/Shanghai")
        let days = (week - 1) * 7 + weekday // first week has index 1, thus it should be subtracted
        let day = calendar.date(byAdding: DateComponents(day: days), to: semesterStart)!
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        
        let startTime = ClassTimeSlot.getItem(start + 1).start
        let startComponent = calendar.dateComponents([.hour, .minute], from: startTime)
        components.hour = startComponent.hour
        components.minute = startComponent.minute
        components.timeZone = timeZone
        let startDate = calendar.date(from: components)!
        
        let endTime = ClassTimeSlot.getItem(end + 1).end
        let endComponent = calendar.dateComponents([.hour, .minute], from: endTime)
        components.hour = endComponent.hour
        components.minute = endComponent.minute
        components.timeZone = timeZone
        let endDate = calendar.date(from: components)!
        
        return (startDate, endDate)
    }
    
    #if !os(watchOS)
    func exportEvents(for eventStore: EKEventStore, to calendar: EKCalendar, semesterStart: Date) throws {
        guard !onWeeks.isEmpty else { return }
        if let recurrentWeek = recurrentWeek {
            let event = EKEvent(eventStore: eventStore)
            event.title = name
            event.location = location
            (event.startDate, event.endDate) = computeTime(from: semesterStart, on: onWeeks.first!)
            let recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: recurrentWeek,
                end: EKRecurrenceEnd(occurrenceCount: (onWeeks.last! - onWeeks.first!) / recurrentWeek + 1)
            )
            event.addRecurrenceRule(recurrenceRule)
            event.calendar = calendar
            try eventStore.save(event, span: .thisEvent, commit: false)
        } else {
            for week in onWeeks {
                let event = EKEvent(eventStore: eventStore)
                event.title = name
                event.location = location
                (event.startDate, event.endDate) = computeTime(from: semesterStart, on: week)
                event.calendar = calendar
                try eventStore.save(event, span: .thisEvent, commit: false)
            }
        }
    }
    #endif
}
