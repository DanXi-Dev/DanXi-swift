import Foundation
#if !os(watchOS)
import Disk
#else
import Utils
#endif
public actor GraduateCourseStore {
    public static let shared = GraduateCourseStore()
    
    var currentSemester: Semester? = nil
    var semesters: [Semester]
    var courseMap: [Semester: [Course]]
    
    init() {
        if let semesters = try? Disk.retrieve("fdutools/grad-semesters.json", from: .appGroup, as: [Semester].self) {
            self.semesters = semesters
        } else {
            self.semesters = []
        }
        
        if let courseMap = try? Disk.retrieve("fdutools/grad-course-map.json", from: .appGroup, as: [Semester: [Course]].self) {
            self.courseMap = courseMap
        } else {
            self.courseMap = [:]
        }
    }
    
    func getCachedCourses(semester: Semester) async throws -> [Course] {
        if let courses = courseMap[semester] {
            if semester == currentSemester {
                try updateCourseModel(with: semester, courses: courses)
            }
            return courses
        }
        
        return try await getRefreshedCourses(semester: semester)
    }
    
    func getRefreshedCourses(semester: Semester) async throws -> [Course] {
        let courses = try await GraduateCourseAPI.getCourses(semester: semester)
        courseMap[semester] = courses
        try Disk.save(courses, to: .appGroup, as: "fdutools/grad-course-map.json")
        
        if semester == currentSemester {
            try updateCourseModel(with: semester, courses: courses)
        }
        
        return courses
    }
    
    func getCachedSemesters() async throws -> [Semester] {
        if !self.semesters.isEmpty {
            return self.semesters
        }
        
        let (semesters, _) = try await getRefreshedSemesters()
        return semesters
    }
    
    public func getRefreshedSemesters() async throws -> ([Semester], Semester?) {
        let (semesters, currentSemester) = try await GraduateCourseAPI.getSemesters()
        self.semesters = semesters
        self.currentSemester = currentSemester
        try Disk.save(semesters, to: .appGroup, as: "fdutools/grad-semesters.json")
        
        if let currentSemester = currentSemester,
           let courses = courseMap[currentSemester] {
                try updateCourseModel(with: currentSemester, courses: courses)
        }
        
        return (semesters, currentSemester)
    }
    
    private func updateCourseModel(with semester: Semester, courses: [Course]) throws {
        _ = computeWeekOffset(from: semester.startDate, courses: courses)
        let cache = CourseModelCache(
            studentType: .grad,
            courses: courses,
            semester: semester,
            semesters: self.semesters
        )
        try Disk.save(cache, to: .appGroup, as: "fdutools/course-model.json")
    }
}
