import Foundation
import SwiftyJSON

struct FDAcademicAPI {
    static func login() async throws {
        let loginURL = URL(string: "http://jwfw.fudan.edu.cn/eams/home.action")!
        _ = try await FDAuthAPI.auth(url: loginURL)
    }
    
    static func getCurrentSemesterId() async throws -> Int? {
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/teach/grade/course/person.action")!
        let request = URLRequest(url: url)
        let (data, _) = try await sendRequest(request)
        let element = try processHTMLData(data, selector: "input[name=\"semesterId\"]")
        let semesterId = Int(try element.attr("value"))
        return semesterId
    }
    
    static func getSemesters() async throws -> [FDSemester] {
        // set semester cookies from server, otherwise the data will not be returned
        let preRequest = URLRequest(url: URL(string: "https://jwfw.fudan.edu.cn/eams/stdExamTable!examTable.action")!)
        _ = try await sendRequest(preRequest)
        
        // request full semester info from server
        let request = prepareFormRequest(URL(string: "https://jwfw.fudan.edu.cn/eams/dataQuery.action")!,
                                         form: [URLQueryItem(name: "dataType", value: "semesterCalendar")])
        let (data, _) = try await sendRequest(request)
        
        // the data sent from server is not real JSON, need to add quotes
        guard var jsonString = String(data: data, encoding: String.Encoding.utf8) else {
            throw ParseError.invalidEncoding
        }
        jsonString.replace(/(?<key>\w+):/) { match in
            return "\"\(match.key)\":"
        }
        jsonString.replace("\n", with: "")
        
        // parse semesters from JSON
        var semesters: [FDSemester] = []
        
        let json = try JSON(data: jsonString.data(using: String.Encoding.utf8)!)["semesters"]
        for (_, arrayJSON) : (String, JSON) in json {
            for (_, semesterJSON) : (String, JSON) in arrayJSON {
                // parse data from JSON
                guard let id = semesterJSON["id"].int else { continue }
                guard let schoolYear = semesterJSON["schoolYear"].string else { continue }
                guard let name = semesterJSON["name"].string else { continue }
                
                // transform data to proper format
                guard let yearName = schoolYear.firstMatch(of: /(\d+)-(\d+)/)?.1 else { continue }
                var kind = FDSemester.Kind.first
                if name.contains("1") {
                    kind = .first
                } else if name.contains("2") {
                    kind = .second
                } else if name.contains("暑") {
                    kind = .summer
                } else if name.contains("寒") {
                    kind = .winter
                }
                
                // append array
                let semester = FDSemester(id: id, year: Int(yearName)!, kind: kind)
                semesters.append(semester)
            }
        }
        
        return semesters.sorted()
    }
    
    static func getScore(semester: Int) async throws -> [FDScore] {
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/teach/grade/course/person!search.action?semesterId=\(String(semester))")!
        let request = URLRequest(url: url)
        let (responseData, _) = try await sendRequest(request)
        let tableElement = try processHTMLData(responseData, selector: "tbody")
        
        var scoreList: [FDScore] = []
        for row in tableElement.children() {
            if row.childNodeSize() > 7 {
                let score = FDScore(courseId: try row.child(2).html(),
                                    name: try row.child(3).html(),
                                    type: try row.child(4).html(),
                                    credit: try row.child(5).html(),
                                    grade: try row.child(6).html(),
                                    gradePoint: try row.child(7).html())
                scoreList.append(score)
            }
        }
        
        return scoreList
    }
    
    static func getGPA() async throws -> [FDRank] {
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/myActualGpa!search.action")!
        let (data, _) = try await sendRequest(URLRequest(url: url))
        let tableElement = try processHTMLData(data, selector: "tbody")
        
        var rankList: [FDRank] = []
        for row in tableElement.children() {
            if row.childNodeSize() > 8 {
                guard let gpa = Double(try row.child(5).html()),
                      let credit = Double(try row.child(6).html()),
                      let rankIndex = Int(try row.child(7).html()) else {
                    continue
                }
                
                let rank = FDRank(name: try row.child(1).html(),
                                  grade: try row.child(2).html(),
                                  major: try row.child(3).html(),
                                  department: try row.child(4).html(),
                                  gpa: gpa,
                                  credit: credit,
                                  rank: rankIndex)
                rankList.append(rank)
            }
        }
        
        return rankList
    }
    
    static func getCourseList(semester: Int? = nil, startWeek: Int = 1) async throws -> (Int, [FDCourse]) {
        // get `ids` and `semesterId` parameter for POST request
        let metaURL = URL(string: "https://jwfw.fudan.edu.cn/eams/courseTableForStd.action")!
        let (data, _) = try await sendRequest(URLRequest(url: metaURL))
        let html = String(data: data, encoding: String.Encoding.utf8)!
        let idsPattern = /bg\.form\.addInput\(form,\s*"ids",\s*"(?<ids>\d+)"\);/
        let semesterIdPattern = /empty:\s*"false",\s*onChange:\s*"",\s*value:\s*"(?<semester>\d+)"/
        guard let ids = html.firstMatch(of: idsPattern)?.ids else {
            throw ParseError.invalidHTML
        }
        var semesterId: Int?
        if let semester = semester {
            semesterId = semester
        } else if let result = html.firstMatch(of: semesterIdPattern) {
            semesterId = Int(result.semester)!
        } else {
            throw ParseError.invalidHTML
        }
        
        // get course table
        let courseURL = URL(string: "https://jwfw.fudan.edu.cn/eams/courseTableForStd!courseTable.action")!
        let form = [URLQueryItem(name: "ignoreHead", value: "1"),
                    URLQueryItem(name: "semester.id", value: String(semesterId!)), // semesterId can't be nil here
                    URLQueryItem(name: "startWeek", value: String(startWeek)),
                    URLQueryItem(name: "setting.kind", value: "std"),
                    URLQueryItem(name: "ids", value: String(ids))]
        let request = prepareFormRequest(courseURL, form: form)
        let (courseData, _) = try await sendRequest(request)
        guard let element = try processHTMLDataList(courseData, selector: "body > script").filter({ try $0.html().contains("new TaskActivity") }).first else {
            return (semesterId!, []) // the semester has no course
        }
        let script = try element.html()
        let lines = script.split(separator: "\n")
        var courseList: [FDCourse] = []
        
        // Regex for matching JS info
        let newCoursePattern = /new TaskActivity\(".*","(?<instructor>.*)","(?<id>\d+)\((?<code>.*)\)","(?<name>.*)\(.*\)","(.*?)","(?<location>.*)","(?<weeks>[01]+)"\);/
        let courseTimePattern = /index\s*=\s*(?<weekday>\d+)\s*\*unitCount\s*\+\s*(?<time>\d+)/
        
        // Parse JS info into an array of course `courseList`
        for line in lines {
            if let result = line.firstMatch(of: newCoursePattern) {
                // JS: `new Activity(<course info>)`, parse and create a new course
                
                let weeksString = String(result.weeks)
                var weeks: [Int] = []
                for (index, character) in weeksString.enumerated() {
                    if character == "1" {
                        weeks.append(index)
                    }
                }
                
                let course = FDCourse(name: String(result.name),
                                      code: String(result.code),
                                      instructor: String(result.instructor),
                                      location: String(result.location),
                                      weeks: weeks)
                courseList.append(course)
            } else if let result = line.firstMatch(of: courseTimePattern) {
                // JS: `index =5*unitCount+10;`, parse and edit course info
                courseList[courseList.count - 1].update(weekday: Int(result.weekday)!,
                                                        time: Int(result.time)!)
            }
        }
        
        return (semesterId!, courseList)
    }
}

// MARK: - Entities

struct FDScore: Identifiable {
    let id = UUID()
    let courseId: String
    let name: String
    let type: String
    let credit: String
    let grade: String
    let gradePoint: String
}


struct FDRank: Identifiable {
    let id = UUID()
    let name: String
    let grade: String
    let major: String
    let department: String
    let gpa: Double
    let credit: Double
    var rank: Int
    
    var isMe: Bool {
        !name.contains("*")
    }
}


struct FDSemester: Identifiable, Comparable, Codable, Hashable {
    let id: Int
    let year: Int
    let kind: Kind
    
    enum Kind: Int, Codable {
        case first = 1, winter, second, summer
    }
    
    func formatted() -> String {
        var name = ""
        switch kind {
        case .first: name = "第1学期"
        case .second: name = "第2学期"
        case .winter: name = "寒假学期"
        case .summer: name = "暑期学期"
        }
        
        return "\(year)-\(year + 1)\(name)"
    }
    
    static func < (lhs: FDSemester, rhs: FDSemester) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        
        return lhs.kind.rawValue < rhs.kind.rawValue
    }
}

struct FDCourse: Identifiable, Codable {
    var id = UUID()
    let name, code: String
    let instructor: String
    let location: String
    let weeks: [Int]
    
    func openOn(_ week: Int) -> Bool {
        weeks.contains(week)
    }
    
    var weekday: Int = 0
    var start: Int = -1
    var end: Int = -1
    mutating func update(weekday: Int, time: Int) {
        self.weekday = weekday
        if end == -1 { // not initialized yet
            start = time
            end = time
        } else {
            end = max(end, time)
        }
    }
}

struct TimeSlot: Identifiable {
    let id: Int
    let start, end: String
    let startTime: DateComponents
    let endTime: DateComponents
    
    init(_ id: Int, _ start: String, _ end: String) {
        self.id = id
        
        self.start = start
        self.end = end
        
        let timeRegex = /(?<hour>\d+):(?<minute>\d+)/
        
        let startMatch = start.wholeMatch(of: timeRegex)!
        var startTime = DateComponents()
        startTime.hour = Int(startMatch.hour)!
        startTime.minute = Int(startMatch.minute)!
        self.startTime = startTime
        
        let endMatch = end.wholeMatch(of: timeRegex)!
        var endTime = DateComponents()
        endTime.hour = Int(endMatch.hour)!
        endTime.minute = Int(endMatch.minute)!
        self.endTime = endTime
    }
    
    static let list = [TimeSlot(1, "08:00", "08:45"),
                       TimeSlot(2, "08:55", "09:40"),
                       TimeSlot(3, "09:55", "10:40"),
                       TimeSlot(4, "10:50", "11:35"),
                       TimeSlot(5, "11:45", "12:30"),
                       TimeSlot(6, "13:30", "14:15"),
                       TimeSlot(7, "14:25", "15:10"),
                       TimeSlot(8, "15:25", "16:10"),
                       TimeSlot(9, "16:20", "17:05"),
                       TimeSlot(10, "17:15", "18:00"),
                       TimeSlot(11, "18:30", "19:15"),
                       TimeSlot(12, "19:25", "20:10"),
                       TimeSlot(13, "20:20", "21:05")]
    
    static func getItem(_ id: Int) -> TimeSlot {
        return list.filter { $0.id == id }.first!
    }
}
