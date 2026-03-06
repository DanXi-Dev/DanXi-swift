import Foundation
#if !os(watchOS)
import Disk
#else
import Utils
#endif

public typealias CaptchaSolver = (_ imageData: Data) async throws -> String

public actor GraduateCourseStore_neo {
    public static let shared = GraduateCourseStore_neo()

    private let loginValidDuration: TimeInterval = 10 * 60

    private var lastLoginTime: Date?
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

    public var requireLogin: Bool {
        guard let lastLoginTime else {
            return true
        }
        return Date().timeIntervalSince(lastLoginTime) > loginValidDuration
    }

    public func getCachedCourse(captchaSolver: CaptchaSolver) async throws -> ([Course], Semester) {
        if let cachedSemester, let cachedCourses {
            return (cachedCourses, cachedSemester)
        }

        return try await getRefreshedCourses(captchaSolver: captchaSolver)
    }

    public func getRefreshedCourses(captchaSolver: CaptchaSolver) async throws -> ([Course], Semester) {
        if requireLogin {
            try await login(captchaSolver: captchaSolver)
        }

        do {
            let (courses, semester) = try await GraduateCourseAPI_neo.getCourses()
            try saveCache(courses: courses, semester: semester)
            return (courses, semester)
        } catch {
            // Session can still expire earlier than local timeout; relogin once then retry.
            try await login(captchaSolver: captchaSolver)
            let (courses, semester) = try await GraduateCourseAPI_neo.getCourses()
            try saveCache(courses: courses, semester: semester)
            return (courses, semester)
        }
    }

    private func login(captchaSolver: CaptchaSolver) async throws {
        guard let username = CredentialStore.shared.username,
              let password = CredentialStore.shared.password else {
            throw CampusError.credentialNotFound
        }
        
        let _ = try await URLSession.campusSession.data(from: URL(string: "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/*default/index.do")!)

        let (imageData, token) = try await GraduateCourseAPI_neo.retrieveCaptcha()
        let captcha = try await captchaSolver(imageData)
        try await GraduateCourseAPI_neo.login(
            username: username,
            password: password,
            captcha: captcha,
            token: token
        )
        lastLoginTime = Date()
    }

    private func saveCache(courses: [Course], semester: Semester) throws {
        cachedCourses = courses
        cachedSemester = semester

        try Disk.save(semester, to: .appGroup, as: "fdutools/grad-semesters.json")
        try Disk.save(courses, to: .appGroup, as: "fdutools/grad-course-map.json")
    }
}
