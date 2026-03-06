import Foundation
import Utils
import SwiftyJSON

public enum GraduateCourseAPI_neo {
    /// Retrieve a captcha image and its paired token from the graduate course system.
    ///
    /// ## API Detail
    ///
    /// 1. GET `/login/4/vcode.do` to retrieve a token from `data.token`.
    /// 2. GET `/login/vcode/image.do?vtoken=<token>` to retrieve image bytes.
    ///
    /// - Returns: A tuple `(imageData, token)` where:
    ///   - `imageData`: Raw image bytes for captcha rendering.
    ///   - `token`: Captcha token used by both image and login endpoints.
    ///
    /// - Throws:
    ///   - ``LocatableError`` if token is missing or response is malformed.
    public static func retrieveCaptcha() async throws -> (Data, String) {
        let captchaTokenURL = URL(string: "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/login/4/vcode.do")!
        let tokenRequest = constructRequest(captchaTokenURL)
        let (tokenData, _) = try await URLSession.campusSession.data(for: tokenRequest)
        let tokenJSON = try JSON(data: tokenData)

        guard let token = tokenJSON["data"]["token"].string, !token.isEmpty else {
            throw LocatableError()
        }

        let captchaImageBaseURL = URL(string: "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/login/vcode/image.do")!
        var imageComponents = URLComponents(url: captchaImageBaseURL, resolvingAgainstBaseURL: false)
        imageComponents?.queryItems = [URLQueryItem(name: "vtoken", value: token)]
        guard let imageURL = imageComponents?.url else {
            throw LocatableError()
        }

        let imageRequest = constructRequest(imageURL)
        let (imageData, _) = try await URLSession.campusSession.data(for: imageRequest)
        return (imageData, token)
    }

    /// Login to the graduate course system using account, captcha answer and token.
    ///
    /// ## API Detail
    ///
    /// POST `/login/check/login.do` with `application/x-www-form-urlencoded` body:
    /// - `loginName`
    /// - `loginPwd`
    /// - `verifyCode`
    /// - `vtoken`
    ///
    /// Example successful response:
    /// ```json
    /// {
    ///   "data": null,
    ///   "jtoken": null,
    ///   "code": "1",
    ///   "msg": "登录成功",
    ///   "timestamp": "******"
    /// }
    /// ```
    ///
    /// Example failed response:
    /// ```json
    /// {
    ///   "data": null,
    ///   "jtoken": null,
    ///   "code": "2",
    ///   "msg": "验证不通过",
    ///   "timestamp": "******"
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - username: Account string submitted as `loginName`.
    ///   - password: Value submitted as `loginPwd`.
    ///     Some deployments require pre-processed password text before submission.
    ///   - captcha: Captcha answer submitted as `verifyCode`.
    ///   - token: Captcha token (`vtoken`) returned by ``retrieveCaptcha()``.
    public static func login(username: String, password: String, captcha: String, token: String) async throws {
        let loginURL = URL(string: "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/login/check/login.do?")!
        let encryptedPassword = DES.encrypt(password)
        var request = constructRequest(loginURL, method: "POST")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // Keep the exact field order and raw vtoken style expected by this endpoint.
        let body = "loginName=\(username)&loginPwd=\(encryptedPassword)&verifyCode=\(captcha)&vtoken=\(token)"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.campusSession.data(for: request)
        let json = try JSON(data: data)
        
        let code = json["code"].stringValue
        if code != "1" {
            throw CampusError.loginFailed
        }
    }

    /// Load graduate course table.
    ///
    /// The endpoint used by this flow is:
    /// `GET http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do?_=<timestamp-ms>`
    ///
    /// Expected response shape:
    /// ```json
    /// {
    ///   "results": [
    ///     {
    ///       "KCMC": "课程名称",
    ///       "JASMC": "教室名称",
    ///       "ZCBH": "周次位串",
    ///       "XQ": 4,
    ///       "KSJCDM": 2,
    ///       "JSXM": "教师姓名",
    ///       "BJDM": "2025202602COMP100001.01"
    ///     }
    ///   ]
    /// }
    /// ```
    ///
    /// - Returns: A tuple of merged courses and inferred semester.
    public static func getCourses() async throws -> ([Course], Semester) {
        var components = URLComponents(string: "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do")!
        components.queryItems = [
            URLQueryItem(name: "_", value: String(Int(Date().timeIntervalSince1970 * 1000)))
        ]
        guard let url = components.url else {
            throw LocatableError()
        }

        let request = constructRequest(url)
        let (data, _) = try await URLSession.campusSession.data(for: request)
        let json = try JSON(data: data)

        let rowsData = try json["results"].rawData()
        let decoder = JSONDecoder()
        let responses = try decoder.decode([CourseResponse].self, from: rowsData)
        let parsed = responses.compactMap(parseCourse)
        let mergedCourses = mergeCourse(parsed.map(\.builder))

        // if no valid semester found, use a fallback one as the code type requires one to be present.
        let fallbackYear = Calendar.current.component(.year, from: Date())
        let fallbackSemester = Semester(
            year: fallbackYear,
            type: .first,      // 秋季学期
            semesterId: fallbackYear * 10 + 1,
            startDate: nil,
            weekCount: max(mergedCourses.flatMap(\.onWeeks).max() ?? 0, 20)
        )

        guard let firstSemester = parsed.first?.semester else {
            return (mergedCourses, fallbackSemester)
        }

        let weekCount = max(mergedCourses.flatMap(\.onWeeks).max() ?? 0, 20)
        let semester = Semester(
            year: firstSemester.year,
            type: firstSemester.type,
            semesterId: firstSemester.semesterId,
            startDate: nil,
            weekCount: weekCount
        )
        return (mergedCourses, semester)
    }

    private static func parseCourse(_ response: CourseResponse) -> ParsedCourse? {
        // 没有 ZCBH 的课程不是本学期课程，直接过滤掉。
        guard let weekmap = response.weekmap, !weekmap.isEmpty else {
            return nil
        }
        guard let weekdayRaw = response.weekday,
              let startRaw = response.startLesson,
              weekdayRaw >= 1,
              startRaw >= 1 else {
            return nil
        }
        let onWeeks = parseWeeks(weekmap)
        if onWeeks.isEmpty {
            return nil
        }

        return ParsedCourse(
            semester: parseSemester(from: response.termCode),
            builder: CourseBuilder(
                name: response.courseName,
                code: parseCode(response.classCode),
                teacher: response.teacherName ?? "",
                location: response.classroomName ?? " ",
                weekday: weekdayRaw - 1,
                start: startRaw - 1,
                end: startRaw - 1,
                onWeeks: onWeeks
            )
        )
    }

    private static func mergeCourse(_ builders: [CourseBuilder]) -> [Course] {
        let sorted = builders.sorted {
            if $0.name != $1.name { return $0.name < $1.name }
            if $0.code != $1.code { return $0.code < $1.code }
            if $0.teacher != $1.teacher { return $0.teacher < $1.teacher }
            if $0.location != $1.location { return $0.location < $1.location }
            if $0.weekday != $1.weekday { return $0.weekday < $1.weekday }
            if $0.onWeeks != $1.onWeeks { return $0.onWeeks.lexicographicallyPrecedes($1.onWeeks) }
            return $0.start < $1.start
        }

        var merged: [CourseBuilder] = []
        for builder in sorted {
            if var last = merged.last, canMerge(last, builder) {
                last.end = builder.end
                merged[merged.count - 1] = last
            } else {
                merged.append(builder)
            }
        }

        return merged.map { $0.build() }
    }

    private static func canMerge(_ lhs: CourseBuilder, _ rhs: CourseBuilder) -> Bool {
        lhs.name == rhs.name &&
        lhs.code == rhs.code &&
        lhs.teacher == rhs.teacher &&
        lhs.location == rhs.location &&
        lhs.weekday == rhs.weekday &&
        lhs.onWeeks == rhs.onWeeks &&
        rhs.start == lhs.end + 1
    }

    private static func parseWeeks(_ weekmap: String) -> [Int] {
        let bitmap = "0" + weekmap
        var result: [Int] = []
        for (index, char) in bitmap.enumerated() where char == "1" {
            result.append(index)
        }
        return result
    }

    private static func parseCode(_ bjdm: String?) -> String {
        guard let bjdm, !bjdm.isEmpty else { return "" }
        let trimmed = bjdm.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 10 {
            return ""
        }
        return String(trimmed.dropFirst(10))
    }

    private static func parseSemester(from termCode: String?) -> ParsedSemester? {
        guard let termCode,
              termCode.count == 5 || termCode.count == 10 else {
            return nil
        }

        let normalized: String
        if termCode.count == 5 {
            normalized = termCode
        } else {
            // e.g. 2025202602 -> use academic start year + term as 20252
            normalized = String(termCode.prefix(4)) + String(termCode.suffix(1))
        }

        guard normalized.count == 5,
              let year = Int(normalized.prefix(4)),
              let term = Int(normalized.suffix(1)) else {
            return nil
        }

        // XNXQDM: 1 -> 第一学期(秋季), 2 -> 第二学期(春季)
        let type: Semester.SemesterType
        switch term {
        case 1:
            type = .first   // 秋季学期
        case 2:
            type = .second  // 春季学期
        default:
            return nil
        }

        return ParsedSemester(
            year: year,
            type: type,
            semesterId: Int(normalized) ?? year * 10 + term
        )
    }

    private struct CourseBuilder {
        let name: String
        let code: String
        let teacher: String
        let location: String
        let weekday: Int
        var start: Int
        var end: Int
        let onWeeks: [Int]

        func build() -> Course {
            Course(
                id: UUID(),
                name: name,
                code: code,
                teacher: teacher,
                location: location,
                weekday: weekday,
                start: start,
                end: end,
                onWeeks: onWeeks
            )
        }
    }

    private struct ParsedSemester {
        let year: Int
        let type: Semester.SemesterType
        let semesterId: Int
    }

    private struct ParsedCourse {
        let semester: ParsedSemester?
        let builder: CourseBuilder
    }

    private struct CourseResponse: Decodable {
        let courseName: String
        let classroomName: String?
        let weekmap: String?
        let weekday: Int?
        let startLesson: Int?
        let teacherName: String?
        let classCode: String?
        let termCode: String?

        enum CodingKeys: String, CodingKey {
            case courseName = "KCMC"      // 课程名称
            case classroomName = "JASMC"  // 教室名称
            case weekmap = "ZCBH"         // 周次编号（位串）
            case weekday = "XQ"           // 星期
            case startLesson = "KSJCDM"   // 开始节次代码
            case teacherName = "JSXM"     // 教师姓名
            case classCode = "BJDM"       // 班级代码（前10位为学期编码）
            case termCode = "XNXQDM"      // 学年学期代码（如 20252）
        }
    }
}
