import Foundation
#if !os(watchOS)
import Disk
#else
import Utils
#endif

public actor GraduateCourseStore_neo {
    public static let shared = GraduateCourseStore_neo()

    private var cachedSemester: Semester?
    private var cachedCourses: [Course]?

    init() {
        if let semester = try? Disk.retrieve("fdutools/grad-semesters.json", from: .appGroup, as: Semester.self) {
            self.cachedSemester = semester
        }

        if let courses = try? Disk.retrieve("fdutools/grad-course-map.json", from: .appGroup, as: [Course].self) {
            self.cachedCourses = courses
        }
    }

    public func getCachedCourse() async throws -> ([Course], Semester) {
        if let cachedSemester, let cachedCourses {
            return (cachedCourses, cachedSemester)
        }

        return try await getRefreshedCourses()
    }

    public func getRefreshedCourses() async throws -> ([Course], Semester) {
        let (courses, fetchedSemester) = try await GraduateCourseAPI_neo.getCourses()
        var semester = fetchedSemester
        // The course table endpoint does not report a start date, keep the one previously
        // fetched or set by the user.
        semester.startDate = fetchedSemester.startDate ?? cachedSemester?.startDate
        try saveCache(courses: courses, semester: semester)
        return (courses, semester)
    }

    private func saveCache(courses: [Course], semester: Semester) throws {
        cachedCourses = courses
        cachedSemester = semester

        try Disk.save(semester, to: .appGroup, as: "fdutools/grad-semesters.json")
        try Disk.save(courses, to: .appGroup, as: "fdutools/grad-course-map.json")
    }
}
