import Foundation
import SwiftyJSON

/// API collection for academic and courses service.
/// These API are only available to undergraduate students.
public enum UndergraduateCourseAPI {
    
    static let loginURL = URL(string: "http://jwfw.fudan.edu.cn/eams/home.action")!
    
    // MARK: - Courses
    
    /// Get all semesters from server
    ///
    /// - Returns:
    ///      A list of semesters
    ///
    /// ## API Detail
    ///
    /// The server use cookie to store user's semester settings.
    /// When querying `https://jwfw.fudan.edu.cn/eams/stdExamTable!examTable.action`, it will set
    /// cookie item `semester.id`. This will be the current semester ID.
    ///
    /// Then, we'll submit a post request to `dataQuery.action` with parameter `dataType = semesterCalendar`, the response is
    /// as follows:
    /// ```json
    /// {yearDom:"
    /// <tr>
    ///     <td class='calendar-bar-td-blankBorder' index='0'>1994-1995</td>
    ///     <td class='calendar-bar-td-blankBorder' index='1'>1995-1996</td>
    ///     <td class='calendar-bar-td-blankBorder' index='2'>1996-1997</td>
    /// </tr>
    /// ...
    /// ",semesters:{y0:[{id:163,schoolYear:"1994-1995",name:"1"},
    /// {id:164,schoolYear:"1994-1995",name:"2"}],
    /// y1:[{id:161,schoolYear:"1995-1996",name:"1"},{id:162,schoolYear:"1995-1996",name:"2"}],
    /// y2:[{id:159,schoolYear:"1996-1997",name:"1"},{id:160,schoolYear:"1996-1997",name:"2"}],
    /// y3:[{id:142,schoolYear:"1997-1998",name:"1"},{id:158,schoolYear:"1997-1998",name:"2"}],
    /// ...
    /// y29:[{id:444,schoolYear:"2023-2024",name:"1"},{id:465,schoolYear:"2023-2024",name:"寒假"},{id:464,schoolYear:"2023-2024",name:"2"}]},
    /// yearIndex:"29",termIndex:"2",semesterId:"464"}
    /// ```
    /// It will be parsed to get all semesters. Note that this is not JSON since the key are not quoted with ".
    public static func getSemesters() async throws -> [Semester] {
        // set semester cookies from server, otherwise the data will not be returned
        _ = try await Authenticator.shared.authenticate(URL(string: "https://jwfw.fudan.edu.cn/eams/stdExamTable!examTable.action")!, manualLoginURL: loginURL)
        
        // request semester data from server
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/dataQuery.action")!
        let request = constructFormRequest(url, form: ["dataType": "semesterCalendar"])
        let data = try await Authenticator.shared.authenticate(request, manualLoginURL: loginURL)
        
        // the data sent from server is not real JSON, need to add quotes
        guard var jsonString = String(data: data, encoding: String.Encoding.utf8) else {
            throw URLError(.badServerResponse)
        }
        jsonString.replace(/(?<key>\w+):/) { match in
            return "\"\(match.key)\":"
        }
        jsonString.replace("\n", with: "")
        let json = try JSON(data: jsonString.data(using: String.Encoding.utf8)!)
        
        // parse semesters from JSON
        var semesters: [Semester] = []
        
        for (_, arrayJSON) : (String, JSON) in json["semesters"] {
            for (_, semesterJSON) : (String, JSON) in arrayJSON {
                // parse data from JSON
                guard let id = semesterJSON["id"].int else { continue }
                guard let schoolYear = semesterJSON["schoolYear"].string else { continue }
                guard let name = semesterJSON["name"].string else { continue }
                
                // transform data to proper format
                guard let yearName = schoolYear.firstMatch(of: /(\d+)-(\d+)/)?.1 else { continue }
                let year = Int(yearName)! // this must sucess since the regex match only include digits
                
                var type = Semester.SemesterType.first
                if name.contains("1") {
                    type = .first
                } else if name.contains("2") {
                    type = .second
                } else if name.contains("暑") {
                    type = .summer
                } else if name.contains("寒") {
                    type = .winter
                }
                
                // append array
                let semester = Semester(year: year, type: type, semesterId: id, startDate: nil, weekCount: 18)
                semesters.append(semester)
            }
        }
        
        return semesters
    }
    
    /// The course table query must include 2 parameters: `semester.id` representing the semester to query, and
    /// `ids` representing student's identity. This function will fetch for these 2 parameters.
    /// - Returns: `(semesterId, ids)
    ///
    /// ## API Detail
    ///
    /// The server will respond with an HTML page, which include the following script:
    /// ```js
    /// semesterCalendar({empty:"false",onChange:"",value:"123"},"searchTable()")
    /// ...
    /// if(jQuery("#courseTableType").val()=="std"){
    ///   bg.form.addInput(form,"ids","123456");
    /// } else {
    ///   bg.form.addInput(form,"ids","");
    /// }
    /// ```
    /// We'll extract the information we need using Regex.
    public static func getParamsForCourses() async throws -> (Int, String) {
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/courseTableForStd.action")!
        let data = try await Authenticator.shared.authenticate(url, manualLoginURL: loginURL)
        let html = String(data: data, encoding: String.Encoding.utf8)!
        
        let idsPattern = /bg\.form\.addInput\(form,\s*"ids",\s*"(?<ids>\d+)"\);/
        guard let ids = html.firstMatch(of: idsPattern)?.ids else {
            throw URLError(.badServerResponse)
        }
        
        let semesterIdPattern = /empty:\s*"false",\s*onChange:\s*"",\s*value:\s*"(?<semester>\d+)"/
        guard let semesterIdString = html.firstMatch(of: semesterIdPattern)?.semester,
              let semesterId = Int(semesterIdString) else {
            throw URLError(.badServerResponse)
        }
        
        return (semesterId, String(ids))
    }
    
    /// Get course table for undergraduate
    /// - Parameters:
    ///   - semesterId: semester ID
    ///   - ids: An internal parameter used to identify student type, can be retrieved by ``getParamsForCourses``
    ///   - startWeek: week number, default 1
    /// - Returns: A list of ``Course``, representing student course table
    public static func getCourses(semesterId: Int, ids: String, startWeek: Int = 1) async throws -> [Course] {
        // retrieve data from server
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/courseTableForStd!courseTable.action")!
        let form = ["ignoreHead": "1",
                    "semester.id": String(semesterId),
                    "startWeek": String(startWeek),
                    "setting.kind": "std",
                    "ids": String(ids)]
        let request = constructFormRequest(url, form: form)
        let data = try await Authenticator.shared.authenticate(request, manualLoginURL: loginURL)
        
        // get script content
        guard let elements = try? decodeHTMLElementList(data, selector: "body > script"),
              let scripts = try? elements.map({ try $0.html() }),
              let script = scripts.filter({ $0.contains("new TaskActivity") }).first else {
                  return [] //  the semester has no course
              }
        
        // regex for matching in script
        let newCoursePattern = /new TaskActivity\(".*","(?<teacher>.*)","(?<id>\d+)\((?<code>.*)\)","(?<name>.*)\(.*\)","(.*?)","(?<location>.*)","(?<weeks>[01]+)"\);/
        let courseTimePattern = /index\s*=\s*(?<weekday>\d+)\s*\*unitCount\s*\+\s*(?<time>\d+)/
        
        struct CourseBuilder {
            let id = UUID()
            let name, code, teacher, location: String
            var weekday = 0, start = -1, end = -1
            let onWeeks: [Int]
            
            var updated = false
            
            mutating func update(weekday: Int, time: Int) {
                self.weekday = weekday
                if !updated {
                    start = time
                    end = time
                } else {
                    end = max(end, time)
                }
                updated = true
            }
            
            func build() -> Course? {
                guard updated else { return nil }
                return Course(id: id, name: name, code: code, teacher: teacher, location: location, weekday: weekday, start: start, end: end, onWeeks: onWeeks)
            }
        }
        
        // parse script confor linetent into courses
        var courses: [Course] = []
        let lines = script.split(separator: "\n")
        var courseBuilder: CourseBuilder? // a course need 2 line to construct, this is a place to temporarily store the info before appending it to result
        
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
                
                // this script line doesn't contain all information needed to build a course, so it is temporarily stored in courseBuilder for further update
                courseBuilder = CourseBuilder(name: String(result.name), code: String(result.code), teacher: String(result.teacher), location: String(result.location), onWeeks: weeks)
            } else if let result = line.firstMatch(of: courseTimePattern) {
                // JS: `index =5*unitCount+10;`, parse and edit course info
                courseBuilder?.update(weekday: Int(result.weekday)!, time: Int(result.time)!) // force init Int because the regex match pattern is \d+, it can't fail
                // depending on whether the course have already been inserted into array, pop it out and re-insert or simply append it at last
                if let course = courseBuilder?.build() {
                    if courses.last?.id == course.id {
                        courses.removeLast()
                    }
                    courses.append(course)
                }
            }
        }
        
        return courses
    }
    
    // MARK: - Score and GPA
    
    /// Get the student course score on a given semeser
    /// - Parameter semester: Semester ID
    /// - Returns: A list of ``Score``
    public static func getScore(semester: Int) async throws -> [Score] {
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/teach/grade/course/person!search.action?semesterId=\(String(semester))")!
        let data = try await Authenticator.shared.authenticate(url, manualLoginURL: loginURL)
        
        let table = try decodeHTMLElement(data, selector: "tbody")
        
        var scores: [Score] = []
        for element in table.children() {
            if element.childNodeSize() > 7 { // check child size before accessing child() to prevent crash
                let score = Score(id: UUID(), courseId: try element.child(2).html(), courseName:  try element.child(3).html(), courseType: try element.child(4).html(), courseCredit: try element.child(5).html(), grade: try element.child(6).html(), gradePoint: try element.child(7).html())
                scores.append(score)
            }
        }
        
        return scores
    }
    
    /// Get the rank list, aka GPA ranking table
    public static func getRanks() async throws -> [Rank] {
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/myActualGpa!search.action")!
        let data = try await Authenticator.shared.authenticate(url, manualLoginURL: loginURL)
        
        let table = try decodeHTMLElement(data, selector: "tbody")
        
        var ranks: [Rank] = []
        
        for element in table.children() {
            if table.childNodeSize() > 8 { // check child size before accessing child() to prevent crash
                guard let gradePoint = Double(try element.child(5).html()),
                      let credit = Double(try element.child(6).html()),
                      let rankIndex = Int(try element.child(7).html()) else {
                    continue
                }
                
                let rank = Rank(id: UUID(), name: try element.child(1).html(), grade: try element.child(2).html(), major: try element.child(3).html(), department: try element.child(4).html(), gradePoint: gradePoint, credit: credit, rank: rankIndex)
                ranks.append(rank)
            }
        }
        
        return ranks
    }
}
