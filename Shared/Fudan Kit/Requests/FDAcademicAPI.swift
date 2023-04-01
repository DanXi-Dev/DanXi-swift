import Foundation
import SwiftyJSON

struct FDAcademicAPI {
    static func login() async throws {
        let loginURL = URL(string: "http://jwfw.fudan.edu.cn/eams/home.action")!
        _ = try await FDAuthAPI.auth(url: loginURL)
    }
    
    static func getSemesters() async throws -> [FDSemester] {
        // set semester cookies from server
        let preRequest = URLRequest(url: URL(string: "https://jwfw.fudan.edu.cn/eams/stdExamTable!examTable.action")!)
        _ = try await sendRequest(preRequest)
        
        // request full semester info from server
        let request = prepareFormRequest(URL(string: "https://jwfw.fudan.edu.cn/eams/dataQuery.action")!,
                                         form: [URLQueryItem(name: "dataType", value: "semesterCalendar")])
        let (data, _) = try await sendRequest(request)
        
        // the data sent from server is not real JSON, need to add quotes
        guard var jsonString = String(data: data, encoding: String.Encoding.utf8) else {
            throw NetworkError.invalidResponse
        }
        
        jsonString.replace(/(?<key>\w+):/) { match in
            return "\"\(match.key)\":"
        }
        jsonString.replace("\n", with: "")
        
        // parse semesters from JSON
        var semesters: [FDSemester] = []
        
        let json = try JSON(data: jsonString.data(using: String.Encoding.utf8)!)["semesters"]
        for (_, subJson) : (String, JSON) in json {
            semesters.append(contentsOf: try JSONDecoder().decode([FDSemester].self,
                                                                  from: try subJson.rawData()))
        }
        
        return semesters.sorted { $0.id < $1.id } // sort by ID
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
    
    static func getCourseList(semester: Int? = nil, startWeek: Int = 1) async throws -> [FDCourse] {
        // get ids param
        let metaURL = URL(string: "https://jwfw.fudan.edu.cn/eams/courseTableForStd.action")!
        let (data, _) = try await sendRequest(URLRequest(url: metaURL))
        let html = String(data: data, encoding: String.Encoding.utf8)!
        let idsPattern = /bg\.form\.addInput\(form,\s*"ids",\s*"(?<ids>\d+)"\);/
        let semesterIdPattern = /empty:\s*"false",\s*onChange:\s*"",\s*value:\s*"(?<semester>\d+)"/
        guard let ids = html.firstMatch(of: idsPattern)?.ids else {
            throw NetworkError.invalidResponse
        }
        
        // get semesterId param
        var semesterId: String?
        if let semester = semester {
            semesterId = String(semester)
        } else if let result = html.firstMatch(of: semesterIdPattern) {
            semesterId = String(result.semester)
        } else {
            throw NetworkError.invalidResponse
        }
        
        // get course table
        let courseURL = URL(string: "https://jwfw.fudan.edu.cn/eams/courseTableForStd!courseTable.action")!
        let form = [URLQueryItem(name: "ignoreHead", value: "1"),
                    URLQueryItem(name: "semester.id", value: semesterId!), // semesterId can't be nil here
                    URLQueryItem(name: "startWeek", value: String(startWeek)),
                    URLQueryItem(name: "setting.kind", value: "std"),
                    URLQueryItem(name: "ids", value: String(ids))]
        let request = prepareFormRequest(courseURL, form: form)
        let (courseData, _) = try await sendRequest(request)
        let element = try processHTMLData(courseData, selector: "body > script:nth-of-type(3)")
        let script = try element.html()
        let lines = script.split(separator: "\n")
        var courseList: [FDCourse] = []
        
        // Regex for matching JS info
        let newCoursePattern = /new TaskActivity\("(?<id>.*)","(?<instructor>.*)","\d+\((?<code>.*)\)","(?<name>.*)\(.*\)","(.*?)","(?<location>.*)","(.*?)"\);/
        let courseTimePattern = /index\s*=\s*(?<weekday>\d+)\s*\*unitCount\s*\+\s*(?<time>\d+)/
        
        // Parse JS info into an array of course `courseList`
        for line in lines {
            if let result = line.firstMatch(of: newCoursePattern) {
                // JS: `new Activity(<course info>)`, parse and create a new course
                let course = FDCourse(id: Int(result.id) ?? 0,
                                  instructor: String(result.instructor),
                                  code: String(result.code),
                                  name: String(result.name),
                                  location: String(result.location))
                courseList.append(course)
            } else if let result = line.firstMatch(of: courseTimePattern) {
                // JS: `index =5*unitCount+10;`, parse and edit course info
                let last = courseList.count - 1
                // weekday, time pattern is \d+, so this should be Int, using force unwrap
                courseList[last].weekday = Int(result.weekday)!
                let time = Int(result.time)!
                if courseList[last].startTime == 0 {
                    courseList[last].startTime = time
                } else {
                    courseList[last].endTime = max(courseList[last].endTime, time)
                }
            }
        }
        
        return courseList
    }
}

struct FDSemester: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let schoolYear: String
    let name: String
    
    func formatted() -> LocalizedStringResource {
        switch name {
        case "1":
            return LocalizedStringResource("\(String(schoolYear)) Fall Semester")
        case "2":
            return LocalizedStringResource("\(String(schoolYear)) Spring Semester")
        case "寒假":
            return LocalizedStringResource("\(String(schoolYear)) Winter Vacation")
        case "暑期":
            return LocalizedStringResource("\(String(schoolYear)) Summer Vacation")
        default:
            return "\(schoolYear) \(name)"
        }
    }
}

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
    let rank: Int
    
    var isMe: Bool {
        !name.contains("*")
    }
}

struct FDCourse: Identifiable, Codable {
    let id: Int
    let instructor: String
    let code: String
    let name: String
    let location: String
    var weekday = 0
    var startTime = 0
    var endTime = 0
}

struct FDCourseTable: Codable {
    let week: Int
    let courses: [FDCourse]
}

struct FDTimeSlot: Identifiable {
    let id: Int
    let startTime: String
    let endTime: String
    
    static let list = [FDTimeSlot(id: 1, startTime: "08:00", endTime: "08:45"),
                       FDTimeSlot(id: 2, startTime: "08:55", endTime: "09:40"),
                       FDTimeSlot(id: 3, startTime: "09:55", endTime: "10:40"),
                       FDTimeSlot(id: 4, startTime: "10:50", endTime: "11:35"),
                       FDTimeSlot(id: 5, startTime: "11:45", endTime: "12:30"),
                       FDTimeSlot(id: 6, startTime: "13:30", endTime: "14:15"),
                       FDTimeSlot(id: 7, startTime: "14:25", endTime: "15:10"),
                       FDTimeSlot(id: 8, startTime: "15:25", endTime: "16:10"),
                       FDTimeSlot(id: 9, startTime: "16:20", endTime: "17:05"),
                       FDTimeSlot(id: 10, startTime: "17:15", endTime: "18:00"),
                       FDTimeSlot(id: 11, startTime: "18:30", endTime: "19:15"),
                       FDTimeSlot(id: 12, startTime: "19:25", endTime: "20:10")]
}


