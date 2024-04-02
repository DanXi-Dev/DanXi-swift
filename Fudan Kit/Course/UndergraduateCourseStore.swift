import Foundation
import Disk

public actor UndergraduateCourseStore {
    public static let shared = UndergraduateCourseStore()
    
    private var currentSemesterId: Int? = nil
    private var ids: String? = nil
    
    var logged = false
    var semesters: [Semester]
    var courseMap: [Semester: [Course]]
    
    func checkLogin() async throws {
        if !logged {
            try await UndergraduateCourseAPI.login()
            logged = true
        }
    }
    
    /// Initialize information from local cache
    init() {
        if let semesters = try? Disk.retrieve("fdutools/undergrad-semesters.json", from: .applicationSupport, as: [Semester].self) {
            self.semesters = semesters
        } else {
            self.semesters = []
        }
        
        if let courseMap = try? Disk.retrieve("fdutools/undergrad-course-map.json", from: .applicationSupport, as: [Semester: [Course]].self) {
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
        
        let (semesters, _) = try await getRefreshedSemesters()
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
        try await checkLogin()
        
        let semesters = try await UndergraduateCourseAPI.getSemesters()
        let (currentSemesterId, _) = try await getNecessaryParams()
        let currentSemester = semesters.filter({ $0.semesterId == currentSemesterId }).first
        self.semesters = semesters
        try Disk.save(semesters, to: .applicationSupport, as: "fdutools/undergrad-semesters.json")
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
        try await checkLogin()
        let (_, ids) = try await getNecessaryParams()
        let courses = try await UndergraduateCourseAPI.getCourses(semesterId: semester.semesterId, ids: ids)
        self.courseMap[semester] = courses
        try Disk.save(self.courseMap, to: .applicationSupport, as: "fdutools/undergrad-course-map.json")
        return courses
    }
}
