import Foundation
import SwiftyJSON

struct FDGradAgendaAPI {
    static func getSemesters() async throws -> FDGradCalendar {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanyjskb/wap/default/get-index")!
        let data = try await FDAuthAPI.auth(url: url)
        let json = try unwrapJSON(data)
        let semestersData = try json["termInfo"].rawData()
        let semesters = try JSONDecoder().decode([FDGradTerm].self, from: semestersData)
        
        
        let currentJSON = json["params"]
        guard let currentYear = currentJSON["year"].string,
              let currentTerm = currentJSON["term"].string,
              let currentWeek = currentJSON["week"].int,
              let current = semesters.filter({ $0.year == currentYear && $0.term == currentTerm }).first else {
            throw ParseError.invalidJSON
        }
        
        return FDGradCalendar(current: current, currentWeek: currentWeek, all: semesters)
    }
    
    static func getAllCourses(term: FDGradTerm) async throws -> Dictionary<Int, [FDGradCourse]> {
        return try await withThrowingTaskGroup(of: (Int, [FDGradCourse]).self, returning: Dictionary<Int, [FDGradCourse]>.self) { taskGroup in
            var dict = Dictionary<Int, [FDGradCourse]>()
            for week in 1...term.totalWeek {
                taskGroup.addTask {
                    let courses = try await FDGradAgendaAPI.getCourses(term: term, week: week)
                    return (week, courses)
                }
            }
            for try await (week, courses) in taskGroup {
                dict[week] = courses
            }
            return dict
        }
    }
    
    static func getCourses(term: FDGradTerm, week: Int) async throws -> [FDGradCourse] {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanyjskb/wap/default/get-data")!
        let form = [
            URLQueryItem(name: "year", value: term.year),
            URLQueryItem(name: "term", value: term.term),
            URLQueryItem(name: "week", value: String(week)),
            URLQueryItem(name: "type", value: "1")
        ]
        let request = prepareFormRequest(url, form: form)
        let (data, _) = try await sendRequest(request)
        let json = try unwrapJSON(data)
        let courseData = try json["classes"].rawData()
        let courses: [FDGradCourse] = try processJSONData(courseData)
        return mergeCourses(courses)
    }
    
    static func mergeCourses(_ unmerged: [FDGradCourse]) -> [FDGradCourse] {
        var merged: [FDGradCourse] = []
        for course in unmerged {
            // if the same course is already processed, continue
            guard merged.filter({ $0.code == course.code && $0.weekday == course.weekday }).isEmpty else {
                continue
            }
            // find all course with the same ID and on same day, and merge start time and end time
            let matched = unmerged.filter { $0.code == course.code && $0.weekday == course.weekday }
            guard let start = matched.map(\.start).min(),
                  let end = matched.map(\.end).max() else {
                continue
            }
            var mergedCourse = course
            mergedCourse.start = start
            mergedCourse.end = end
            merged.append(mergedCourse)
        }
        return merged
    }
}

// MARK: - Model

struct FDGradCalendar {
    let current: FDGradTerm
    let currentWeek: Int
    let all: [FDGradTerm]
}

struct FDGradTerm: Identifiable, Decodable {
    let id = UUID()
    let year: String
    let term: String
    let startDay: Date
    let totalWeek: Int
    
    enum CodingKeys: String, CodingKey {
        case year
        case term
        case startDay = "startday"
        case totalWeek = "countweek"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.year = try container.decode(String.self, forKey: .year)
        self.term = try container.decode(String.self, forKey: .term)
        self.totalWeek = try container.decode(Int.self, forKey: .totalWeek)
        
        let dateString = try container.decode(String.self, forKey: .startDay)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else {
            throw ParseError.invalidDateFormat
        }
        self.startDay = date
    }
}

struct FDGradCourse: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let code: String
    let location: String
    let credit: Int
    let teacher: String
    
    let weekday: Int
    var start: Int
    var end: Int
    
    enum CodingKeys: String, CodingKey {
        case name = "course_name"
        case code = "course_id"
        case location
        case credit
        case teacher
        case weekday
        case lessons
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        code = try container.decode(String.self, forKey: .code)
        location = try container.decode(String.self, forKey: .location)
        credit = try container.decode(Int.self, forKey: .credit)
        teacher = try container.decode(String.self, forKey: .teacher)
        weekday = try container.decode(Int.self, forKey: .weekday)
        guard let lessons = Int(try container.decode(String.self, forKey: .lessons)) else {
            throw ParseError.invalidJSON
        }
        start = lessons
        end = lessons
    }
}
