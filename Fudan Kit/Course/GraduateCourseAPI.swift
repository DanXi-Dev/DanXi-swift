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
        let data = try await Authenticator.shared.authenticate(url)
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
                    let term = semester.type == .first ? 1 : 2
                    let builders = try await getCoursesForWeek(
                        year: semester.year, term: term, week: week)
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
    private static func getCoursesForWeek(year: Int, term: Int, week: Int) async throws
        -> [CourseBuilder]
    {
        // get data from server
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanyjskb/wap/default/get-data")!
        let form = [
            "year": "\(String(year))-\(String(year + 1))",
            "term": String(term),
            "week": String(week),
            "type": "1",
        ]
        let request = constructFormRequest(url, form: form)
        let data = try await Authenticator.shared.authenticate(request)

        // decode data into GraduateCourseResponse
        let json = try unwrapJSON(data)
        let courseData = try json["classes"].rawData()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        var responses = try decoder.decode([CourseResponse].self, from: courseData)

        // consecutive courses are separated in response
        // we need to merge same course into a single course builder
        var builders: [CourseBuilder] = []

        while !responses.isEmpty {
            let response = responses.removeFirst()
            var matchedResponses = responses.filter {
                $0.courseId == response.courseId && $0.weekday == response.weekday
            }
            matchedResponses.append(response)
            responses.removeAll {
                $0.courseId == response.courseId && $0.weekday == response.weekday
            }

            // get all \.lessons array. If parse to int fails, throw error.
            let lessons = try matchedResponses.map { item in
                guard let lesson = Int(item.lessons) else {
                    throw LocatableError()
                }
                return lesson - 1
            }
            guard let max = lessons.max(), let min = lessons.min() else { continue }
            let builder = CourseBuilder(
                name: response.courseName, code: response.courseId, teacher: response.teacher,
                location: response.location, weekday: response.weekday, start: min, end: max)
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
        let courseName: String
        let courseId: String
        let location: String
        let credit: Int
        let teacher: String
        let weekday: Int
        let lessons: String
    }

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
        let data = try await Authenticator.shared.authenticate(url, manualLoginURL: loginURL)
        
        let string = String(data: data, encoding: .utf8)!
        print(string)

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

func closestMonday(to date: Date) -> Date? {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date)
    let daysToMonday = (2 - weekday + 7) % 7
    return calendar.date(byAdding: .day, value: daysToMonday, to: date)
}
