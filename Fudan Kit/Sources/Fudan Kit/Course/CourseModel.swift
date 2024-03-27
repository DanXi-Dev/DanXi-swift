import SwiftUI
import Disk

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
        let model = CourseModel(studentType: .undergrad, courses: courses, semester: currentSemester, semesters: semesters, week: week)
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
    public static func loadCache(for studentType: StudentType) async throws -> CourseModel? {
        guard let cache = try? Disk.retrieve("fdutools/course-model.json", from: .applicationSupport, as: CourseModelCache.self) else {
            return nil
        }
        
        guard cache.studentType == studentType else {
            Task(priority: .background) {
                try Disk.remove("fdutools/course-model.json", from: .applicationSupport)
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
    @Published public var semester: Semester {
        didSet {
            Task {
                await updateSemester()
            }
        }
    }
    @Published public var semesters: [Semester]
    @Published public var week: Int
    @Published public var networkError: Error? = nil
    
    // MARK: - Computed Property
    
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
    
    // MARK: Model Update
    
    /// Work to be done after semester is changed
    @MainActor func updateSemester() async {
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
    public func refresh(with context: [Int: Date]) async {
        do {
            if studentType == .undergrad {
                courses = try await UndergraduateCourseStore.shared.getRefreshedCourses(semester: semester)
                let (semesters, _) = try await UndergraduateCourseStore.shared.getRefreshedSemesters()
                self.semesters = matchUndergraduateSemesterStartDateByContext(semesters: semesters, context: context)
            } else if studentType == .grad {
                courses = try await GraduateCourseStore.shared.getRefreshedCourses(semester: semester)
                let (semesters, _) = try await GraduateCourseStore.shared.getRefreshedSemesters()
                self.semesters = semesters
            }
        } catch {
            networkError = error
        }
    }
    
    
    /// This is for undergraduate student to update semester start date when context change.
    /// - Parameter startDateContext: A context for undergraduate student to match semester start date. It should be retrieved from DanXi backend.
    public func receiveUndergraduateStartDateContextUpdate(startDateContext: [Int: Date]) {
        guard studentType == .undergrad else { return }
        semesters = matchUndergraduateSemesterStartDateByContext(semesters: semesters, context: startDateContext)
        semester.startDate = startDateContext[semester.semesterId]
    }
    
    /// An internal method that persists data to disk when model updates.
    func refreshCache() {
        Task(priority: .background) {
            let cache = CourseModelCache(studentType: studentType, courses: courses, semester: semester, semesters: semesters)
            try Disk.save(cache, to: .applicationSupport, as: "fdutools/course-model.json")
        }
    }
    
    // Utilities
    
    func exportToCalendar() {
        
    }

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
        updatedSemester.startDate = context[semester.semesterId]
        return updatedSemester
    }
}

struct CourseModelCache: Codable {
    let studentType: StudentType
    let courses: [Course]
    let semester: Semester
    let semesters: [Semester]
}

