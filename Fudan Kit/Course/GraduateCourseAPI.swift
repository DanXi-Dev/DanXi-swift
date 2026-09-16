import Foundation
import Utils
import SwiftyJSON

public enum GraduateCourseAPI {
    private static let primaryCourseURL = URL(
        string: "http://yjsxk.fudan.edu.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do"
    )!
    private static let secondaryCourseURL = URL(
        string: "http://yjsxktest.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do"
    )!

    /// Load graduate course table.
    ///
    /// The primary endpoint used by this flow is:
    /// `GET http://yjsxk.fudan.edu.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do?_=<timestamp-ms>`
    ///
    /// If requesting or parsing the primary endpoint fails, the test deployment at
    /// `yjsxktest.fudan.sh.cn` is tried as a fallback. Both deployments use the unified
    /// authentication center (`id.fudan.edu.cn`), handled by ``Authenticator/neo``.
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
        do {
            return try await getCourses(from: primaryCourseURL)
        } catch {
            return try await getCourses(from: secondaryCourseURL)
        }
    }

    private static func getCourses(from endpoint: URL) async throws -> ([Course], Semester) {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw LocatableError()
        }
        components.queryItems = [
            URLQueryItem(name: "_", value: String(Int(Date().timeIntervalSince1970 * 1000)))
        ]
        guard let url = components.url else {
            throw LocatableError()
        }

        let data = try await Authenticator.neo.authenticate(url)
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

extension GraduateCourseAPI {
    // MARK: - Score and GPA

    /// Get the student all course score
    /// - Returns: A list of ``Score``
    ///
    ///
    /// {
    /// "code": "0",
    /// "datas": {
    ///   "jdjscjcx": {
    ///        "totalSize": 8,
    ///        "pageSize": 999,
    ///        "rows": [
    ///             {
    ///             ...
    ///             }
    ///        ]
    ///   }
    ///}
    ///}
    ///
    public static func getScore() async throws -> [Score] {
        let loginURL = URL(string: "https://yzsfwapp.fudan.edu.cn/gsapp/sys/wdcjapp/*default/index.do")!
        let url = URL(string: "https://yzsfwapp.fudan.edu.cn/gsapp/sys/wdcjapp/modules/xscjcx/jdjscjcx.do")!
        let data = try await Authenticator.neo.authenticate(url, loginURL: loginURL)

        var scores: [Score] = []
        guard let json = try? JSON(data: data),
              let code = json["code"].string else {
            throw LocatableError()
        }

        if code != "0" {
            throw LocatableError()
        }

        let scoresData = try json["datas"]["jdjscjcx"]["rows"].rawData()
        let decoder = JSONDecoder()
        let responses = try decoder.decode([ScoreResponse].self, from: scoresData)

        for scoreResponse in responses {
            scores.append(Score(id: UUID(), courseId: scoreResponse.courseId, courseName: scoreResponse.courseName, courseType: scoreResponse.courseType, courseCredit: String( scoreResponse.credit), grade: scoreResponse.grade, gradePoint: String(scoreResponse.gradePoint)))
        }

        return scores
    }

    private struct ScoreResponse: Decodable {
        let courseName: String
        let courseId: String
        let credit: Float
        let teacher: String?
        let courseType: String
        let grade: String
        let gradePoint: Float

        enum CodingKeys: String, CodingKey {
            case courseName = "KCMC"
            case courseId = "KCDM"
            case credit = "XF"
            case teacher = "CZRXM"
            case courseType = "KCLBMC"
            case grade = "CJ"
            case gradePoint = "JDZ"
        }
    }
}

/*
 以下是原研究生课表小程序接口实现。
 由于该数据源更新不及时，现已弃用；代码保留在这里，便于后续追溯或参考。

@preconcurrency import Combine
import Foundation
import Utils
import SwiftyJSON

public enum GraduateCourseAPI {

    /// Get all semesters
    /// - Returns: A tuple of semesters and current semester.
    ///
    /// - Important:
    ///     The `startday` property of the semester may be incorrect in previous semesters.
    ///
    /// ## API Detail
    ///
    /// The server respond with the following JSON data:
    /// ```json
    /// {
    ///     "e": 0,
    ///     "m": "操作成功",
    ///     "d": {
    ///         "params": {
    ///             "year": "2023-2024",
    ///             "term": "2",
    ///             "startday": "2024-02-26",
    ///             "countweek": 18,
    ///             "week": 4
    ///         },
    ///         "termInfo": [
    ///             {
    ///                 "year": "2024-2025",
    ///                 "term": "2",
    ///                 "startday": "2025-03-01",
    ///                 "countweek": 18
    ///             },
    ///             ...
    ///         ],
    ///         "weekday": "3",
    ///         "weekdays": [
    ///             "2024-03-18",
    ///             "2024-03-19",
    ///             "2024-03-20",
    ///             "2024-03-21",
    ///             "2024-03-22",
    ///             "2024-03-23",
    ///             "2024-03-24"
    ///         ]
    ///     }
    /// }
    /// ```
    public static func getSemesters() async throws -> ([Semester], Semester?) {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanyjskb/wap/default/get-index")!
        let data = try await Authenticator.classic.authenticate(url)
        let json = try unwrapJSON(data)
        let semesterData = try json["termInfo"].rawData()

        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let semestersResponse = try decoder.decode([GraduateSemesterResponse].self, from: semesterData)
        var semesters: [Semester] = []
        for response in semestersResponse {
            let yearPattern = /(?<startYear>\d+)-\d+/
            guard let yearMatch = response.year.firstMatch(of: yearPattern),
                  let year = Int(yearMatch.startYear) else {
                continue
            }
            let type: Semester.SemesterType = (response.term == "1") ? .first : .second

            let semester = Semester(
                year: year, type: type, semesterId: 0,
                startDate: closestMonday(to: response.startday), weekCount: response.countweek)
            semesters.append(semester)
        }

        var currentSemester: Semester? = nil

        let currentSemesterYearString = json["params"]["year"].stringValue
        let currentSemsterTermString = json["params"]["term"].stringValue
        if let currentSemesterYearMatch = currentSemesterYearString.firstMatch(of: /(?<startYear>\d+)-\d+/),
           let currentSemesterYear = Int(currentSemesterYearMatch.startYear) {
            let type: Semester.SemesterType = (currentSemsterTermString == "1") ? .first : .second
            currentSemester = semesters.filter({ $0.year == currentSemesterYear && $0.type == type }).first
        }

        return (semesters, currentSemester)
    }

    private struct GraduateSemesterResponse: Decodable {
        let year: String
        let term: String
        let startday: Date
        let countweek: Int
    }

    /// A task-local publisher that allows subroutines to report loading progress to UI.
    public enum LoadingProgress {
        @TaskLocal public static var progressPublisher = PassthroughSubject<Float, Never>()
    }

    /// Get courses on a given semester
    public static func getCourses(semester: Semester) async throws -> [Course] {
        let dictionary = try await withThrowingTaskGroup(of: (Int, [CourseBuilder]).self, returning: [Int: [CourseBuilder]].self) { taskGroup in
            var dictionary: [Int: [CourseBuilder]] = [:]

            for week in 1...semester.weekCount {
                taskGroup.addTask {
                    let builders = try await getCoursesForWeek(startdate: semester.startDate!, week: week)
                    return (week, builders)
                }
            }

            var completedWeeks = 0
            for try await (week, builders) in taskGroup {
                dictionary[week] = builders
                completedWeeks += 1
                // Publish progress to the publisher of this task, obtained from the task-local variable CourseLoadingProgressPublisherKey.progressPublisher
                // If there is no such publisher (nobody asked for progress), the publisher will simply default to a dummy publisher that nobody receives from.
                let progress = Float(completedWeeks) / Float(semester.weekCount)
                let publisher = LoadingProgress.progressPublisher  // Since this publisher is task-local, we must get it before entering main thread
                DispatchQueue.main.async {
                    publisher.send(progress)  // Publishing UI changes must be done on main thread
                }
            }

            return dictionary
        }

        var builders: [CourseBuilder] = []
        for week in 1...semester.weekCount {
            let currentWeekBuilders = dictionary[week]!  // this key is not empty, as it is set in the taskGroup above
            for newBuilder in currentWeekBuilders {
                // if newBuilder is in builders, update builder
                var matched = false
                for (idx, builder) in builders.enumerated() {
                    if builder.code == newBuilder.code && builder.weekday == newBuilder.weekday {
                        builders[idx].onWeeks.append(week)
                        matched = true
                        break  // TODO: which to break?
                    }
                }

                // otherwise it's a new builder, should be appended
                if !matched {
                    var appendedBuilder = newBuilder  // override newBuilder constant
                    appendedBuilder.onWeeks.append(week)
                    builders.append(appendedBuilder)
                }
            }
        }

        return builders.map { $0.build() }
    }

    /// Get courses on a given week
    ///
    /// ## API Detail
    ///
    /// The server response with a following message
    ///
    /// ```json
    /// {
    ///     "e": 0,
    ///     "m": "操作成功",
    ///     "d": {
    ///         "classes": [
    ///             {
    ///                 "course_id": "PTSS732001",
    ///                 "course_name": "新时代中国特色社会主义理论与实践",
    ///                 "location": "JA205",
    ///                 "weekday": 3,
    ///                 "lessons": "06",
    ///                 "week": "1-16",
    ///                 "course_time": "13:30-14:15",
    ///                 "course_type": "政治理论课",
    ///                 "credit": 2,
    ///                 "khfs": "考试",
    ///                 "teacher": "张济琳",
    ///                 "area": ""
    ///             },
    ///             ...,
    ///             {
    ///                 "course_id": "PTSS732001",
    ///                 "course_name": "新时代中国特色社会主义理论与实践",
    ///                 "location": "JA205",
    ///                 "weekday": 3,
    ///                 "lessons": "07",
    ///                 "week": "1-16",
    ///                 "course_time": "14:25-15:10",
    ///                 "course_type": "政治理论课",
    ///                 "credit": 2,
    ///                 "khfs": "考试",
    ///                 "teacher": "张济琳",
    ///                 "area": ""
    ///             }
    ///         ],
    ///         "weekdays": [
    ///             "2024-04-08",
    ///             "2024-04-09",
    ///             "2024-04-10",
    ///             "2024-04-11",
    ///             "2024-04-12",
    ///             "2024-04-13",
    ///             "2024-04-14"
    ///         ]
    ///     }
    /// }
    /// ```
    private static func getCoursesForWeek(startdate: Date, week: Int) async throws
        -> [CourseBuilder]
    {
        // get data from server
        let url = URL(string: "https://yzsfwapp.fudan.edu.cn/gsapp/sys/wdrcappfudan/wdrc/loadRcxx.do")!
        let loginUrl = URL(string:
            "https://yzsfwapp.fudan.edu.cn/gsapp/sys/wdrcappfudan/" +
            "*default/index.do?type=add#/wdrc"
        )

        // cal start and end day
        let calender = Calendar.current
        let startDateOfWeek = calender.date(byAdding: .day, value: 7*(week-1), to: startdate)!
        let endDateOfWeek = calender.date(byAdding: .day, value: 7*week, to: startdate)!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let form = [
            "ksrq": dateFormatter.string(from: startDateOfWeek),
            "jsrq": dateFormatter.string(from: endDateOfWeek),
            "ids": ""
        ]
        let request = constructFormRequest(url, form: form)
        let data = try await Authenticator.neo.authenticate(request, loginURL: loginUrl)

        // decode data into GraduateCourseResponse
        let json = try JSON(data: data)
        let courseData = try json["datas"].rawData()
        let decoder = JSONDecoder()
        let formatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter
        }()
        decoder.dateDecodingStrategy = .formatted(formatter)
        var responses = try decoder.decode([CourseResponse].self, from: courseData)

        // consecutive courses are separated in response
        // we need to merge same course into a single course builder
        var builders: [CourseBuilder] = []

        while !responses.isEmpty {
            let response = responses.removeFirst()
            var matchedResponses = responses.filter {
                $0.title == response.title && $0.kssj.formatted(.dateTime.year().month().day()) == response.kssj.formatted(.dateTime.year().month().day())
            }
            matchedResponses.append(response)
            responses.removeAll {
                $0.title == response.title && $0.kssj.formatted(.dateTime.year().month().day()) == response.kssj.formatted(.dateTime.year().month().day())
            }

            let calender = Calendar.current
            // get all \.lessons array. If parse to int fails, throw error.
            let lessons = try matchedResponses.map { item in
                let lessonIndex = ClassTimeSlot.list.firstIndex { slot in
                    let itemComponents = calender.dateComponents([.hour, .minute], from: item.kssj)
                    let slotComponents = calender.dateComponents([.hour, .minute], from: slot.start)

                    return itemComponents.hour == slotComponents.hour &&
                               itemComponents.minute == slotComponents.minute
                }
                guard let lesson = lessonIndex else {
                    throw LocatableError()
                }
                return lesson
            }
            guard let max = lessons.max(), let min = lessons.min() else { continue }

            let (courseName, courseCode) = try getNameAndCode(from: response.title)
            let weekday = calender.component(.weekday, from: response.kssj)
            let builder = CourseBuilder(
                name: courseName, code: courseCode, teacher: "",
                location: response.dd, weekday: weekday - 1, start: min, end: max)
            builders.append(builder)
        }

        return builders
    }

    private struct CourseBuilder {
        let name, code, teacher, location: String
        let weekday: Int
        var start, end: Int
        var onWeeks: [Int] = []

        func build() -> Course {
            return Course(
                id: UUID(), name: name, code: code, teacher: teacher, location: location,
                weekday: weekday - 1, start: start, end: end, onWeeks: onWeeks)
        }
    }

    private struct CourseResponse: Decodable {
        let title: String
        let jssj: Date
        let kssj: Date
        let dd: String

        enum CodingKeys: String, CodingKey {
            case title = "TITLE"
            case kssj = "KSSJ"
            case jssj = "JSSJ"
            case dd = "DD"
        }
    }
}

func closestMonday(to date: Date) -> Date? {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date)
    let daysToMonday = (2 - weekday + 7) % 7
    return calendar.date(byAdding: .day, value: daysToMonday, to: date)
}

func getNameAndCode(from title: String) throws -> (name: String, code: String) {
    guard let dashRange = title.range(of: "-"),
          let parenthesisRange = title.range(of: "(") else {
            throw LocatableError()
    }

    let startIndex = title.index(after: dashRange.lowerBound)
    let endIndex = parenthesisRange.lowerBound
    let courseName = String(title[startIndex..<endIndex])

    let startOfCodeIndex = title.index(parenthesisRange.lowerBound, offsetBy: courseName.count + 11)

    guard let dotRange = title[startOfCodeIndex...].range(of: ".") else {
           throw LocatableError()
       }

    let courseCode = String(title[startOfCodeIndex..<dotRange.lowerBound])

    return (courseName, courseCode)
}

func getWeekday(from startDate: Date) {

}
*/
