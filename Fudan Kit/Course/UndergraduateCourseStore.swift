import Foundation
#if !os(watchOS)
import Disk
#else
import Utils
#endif

public actor UndergraduateCourseStore {
    public static let shared = UndergraduateCourseStore()
    
    private var currentSemesterId: Int? = nil
    private var ids: String? = nil
    
    var semesters: [Semester]
    var courseMap: [Semester: [Course]]
    
    /// Initialize information from local cache
    init() {
        if let semesters = try? Disk.retrieve("fdutools/undergrad-semesters.json", from: .appGroup, as: [Semester].self) {
            self.semesters = semesters
        } else {
            self.semesters = []
        }
        
        if let courseMap = try? Disk.retrieve("fdutools/undergrad-course-map.json", from: .appGroup, as: [Semester: [Course]].self) {
            self.courseMap = courseMap
        } else {
            self.courseMap = [:]
        }
    }
    
    private func getNecessaryParams() async throws -> (Int, String) {
        if let semesterId = self.currentSemesterId, let ids = self.ids {
            return (semesterId, ids)
        }
        
        let (semesterId, ids) = try await UndergraduateCourseAPI.getParamsForCourses()
        self.currentSemesterId = semesterId
        self.ids = ids
        return (semesterId, ids)
    }
    
    // MARK: Semester
    
    public func getCachedSemesters() async throws -> [Semester] {
        if !semesters.isEmpty {
            return self.semesters
        }
        
        let (semesters, currentSemester) = try await getRefreshedSemesters()
        
        if let currentSemester = currentSemester,
           let courses = courseMap[currentSemester] {
            try updateCourseModel(with: currentSemester, courses: courses)
        }
        
        return semesters
    }
    
    public func getCurrentSemester() async throws -> Semester? {
        if let currentSemesterId = currentSemesterId {
            return self.semesters.filter({ $0.semesterId == currentSemesterId }).first
        }
        
        let (_, currentSemester) = try await getRefreshedSemesters()
        return currentSemester
    }
    
    public func getRefreshedSemesters() async throws -> ([Semester], Semester?) {
        let semesters = try await UndergraduateCourseAPI.getSemesters()
        let (currentSemesterId, _) = try await getNecessaryParams()
        let currentSemester = semesters.filter({ $0.semesterId == currentSemesterId }).first
        self.semesters = semesters
        try Disk.save(semesters, to: .appGroup, as: "fdutools/undergrad-semesters.json")
        
        if let currentSemester = currentSemester,
           let courses = courseMap[currentSemester] {
            try updateCourseModel(with: currentSemester, courses: courses)
        }
        
        return (semesters, currentSemester)
    }
    
    // MARK: Courses
    
    public func getCachedCourses(semester: Semester) async throws -> [Course] {
        if let courses = courseMap[semester] {
            return courses
        }
        
        return try await getRefreshedCourses(semester: semester)
    }
    
    public func getRefreshedCourses(semester: Semester) async throws -> [Course] {
        let (_, ids) = try await getNecessaryParams()
        let courses = try await UndergraduateCourseAPI.getCourses(semesterId: semester.semesterId, ids: ids)
        self.courseMap[semester] = courses
        try Disk.save(self.courseMap, to: .appGroup, as: "fdutools/undergrad-course-map.json")
        
        if semester.semesterId == currentSemesterId {
            try updateCourseModel(with: semester, courses: courses)
        }
        
        return courses
    }
    
    // MARK: Update
    
    private func updateCourseModel(with semester: Semester, courses: [Course]) throws {
        _ = computeWeekOffset(from: semester.startDate, courses: courses)
        let cache = CourseModelCache(
            studentType: .undergrad,
            courses: courses,
            semester: semester,
            semesters: self.semesters
        )
        try Disk.save(cache, to: .appGroup, as: "fdutools/course-model.json")
    }
}
