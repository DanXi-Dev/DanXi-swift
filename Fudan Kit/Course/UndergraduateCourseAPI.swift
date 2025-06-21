import Foundation
import SwiftyJSON
import Utils

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
            throw LocatableError()
        }
        jsonString.replace(/(?<key>\w+):/) { match in
            return "\"\(match.key)\":"
        }
        jsonString.replace("\n", with: "")
        let json = try JSON(data: jsonString.data(using: String.Encoding.utf8)!)
        print(json)
        
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
        let url = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/course-table")!
        var data  = try await Authenticator.shared.authenticate(url, manualLoginURL: loginURL)
        var html  = String(data: data, encoding: .utf8)!
        
        if html.contains(#"onload="doSubmit()""#) {
            
            let ticketPattern  = /name="ticket"\s+value="(?<ticket>[^"]+)"/
            guard let ticket = html.firstMatch(of: ticketPattern)?.ticket else {
                throw LocatableError()
            }

            
            let actionPattern  = /form[^>]+action="(?<action>[^"]+)"/
            guard let action = html.firstMatch(of: actionPattern)?.action,
                  let loginURL = URL(string: action + "&ticket=" + ticket) else {
                throw LocatableError()
            }

            _ = try await Authenticator.shared.authenticate(loginURL, manualLoginURL: loginURL)

            data = try await Authenticator.shared.authenticate(url, manualLoginURL: loginURL)
            html = String(data: data, encoding: .utf8)!
        }

        let semesterIdPattern = /'id':\s*"?(?<semester>\d{3,})"?/
        guard let semesterStr = html.firstMatch(of: semesterIdPattern)?.semester,
              let semesterId  = Int(semesterStr) else {
            throw LocatableError()
        }


        let idsPattern = /var\s+studentIds\s*=\s*\[\s*(?<ids>\d+)\s*\]/
        guard let ids = html.firstMatch(of: idsPattern)?.ids else {
            throw LocatableError()
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
        let url = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/course-table/semester/\(semesterId)/print-data")!
        let courseData = try await Authenticator.shared.authenticate(url, manualLoginURL: loginURL)

        let json = try JSON(data: courseData)
        var courseDict: [String: Course] = [:]
        
        // Solve the problem of the same course with different rooms
        func insert(_ course: Course) {
            let weeksKey = course.onWeeks.sorted().map(String.init).joined(separator: "_")
            let key = "\(course.name)-\(course.code)-\(course.weekday)-\(course.start)-\(course.end)-\(weeksKey)"
            if let existed = courseDict[key] {
                let oldRooms = Set(existed.location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                let newRooms = Set(course.location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                let mergedRooms = Array(oldRooms.union(newRooms))
                    .filter { !$0.isEmpty }
                    .sorted()
                    .joined(separator: ", ")

                let oldTeachers = Set(existed.teacher.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                let newTeachers = Set(course.teacher.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                let mergedTeachers = Array(oldTeachers.union(newTeachers))
                    .filter { !$0.isEmpty }
                    .sorted()
                    .joined(separator: ", ")

                courseDict[key] = Course(
                    id: existed.id,
                    name: existed.name,
                    code: existed.code,
                    teacher: mergedTeachers,
                    location: mergedRooms,
                    weekday: existed.weekday,
                    start: existed.start,
                    end: existed.end,
                    onWeeks: existed.onWeeks
                )
            } else {
                courseDict[key] = course
            }
        }

        if let studentTableVms = json["studentTableVms"].array {
            for studentVM in studentTableVms {
                if let activities = studentVM["activities"].array {
                    for act in activities { if let c = parseCourse(from: act) { insert(c) } }
                }
            }
        } else {
            for (_, lessonJSON):(String, JSON) in json {
                if let c = parseCourse(from: lessonJSON) { insert(c) }
            }
        }

        return Array(courseDict.values)
    }
    
    // get single course
    private static func parseCourse(from json: JSON) -> Course? {
        guard let courseName = json["courseName"].string,
              let lessonCode = json["lessonCode"].string,
              var weekday = json["weekday"].int,
              var startUnit = json["startUnit"].int,
              var endUnit = json["endUnit"].int else {
            return nil
        }

        weekday = max(0, weekday - 1)
        startUnit = max(0, startUnit - 1)
        endUnit   = max(0, endUnit - 1)

        var teacherName = ""
        if let teachers = json["teachers"].array {
            teacherName = teachers
                .compactMap { $0.string }
                .filter { !$0.isEmpty && $0 != "null" }
                .joined(separator: ", ")
        }

        var location = ""
        if let room = json["room"].string, room != "null", !room.isEmpty {
            location = room
        }

        var onWeeks: [Int] = []
        if let weekIndexes = json["weekIndexes"].array {
            onWeeks = weekIndexes.compactMap { $0.int }
        }

        return Course(
            id: UUID(),
            name: courseName,
            code: lessonCode,
            teacher: teacherName,
            location: location,
            weekday: weekday,
            start: startUnit,
            end: endUnit,
            onWeeks: onWeeks
        )
    }

    // MARK: - Exam
    
    /// Get uset's exam list
    ///
    /// ## API Detail
    ///
    /// This API use the cookie `semester.id` to get the exam list. If it's set to different value before, it might return incorrect value.
    ///
    /// The server response with the following content:
    ///
    /// ```swift
    /// <table class="gridtable" style="width:100%;text-align: center" align="center">
    ///     <thead class="gridhead">
    ///         <tr>
    ///             <th style="width: 10%">课程序号</th>
    ///             <th style="width: 8%">课程代码</th>
    ///             <th style="width: 18%">课程名称</th>
    ///             <th style="width: 8%">考试类型</th>
    ///             <th style="width: 11%">考试日期或论文提交日期</th>
    ///             <th style="width: 12%">考试安排</th>
    ///             <th style="width: 8%">考试地点</th>
    ///             <th style="width: 6%">考试方式</th>
    ///             <th style="width: 8%">其它说明</th>
    ///         </tr>
    ///     </thead>
    ///     <tr>
    ///         <td style="width: 10%">PHYS130093h.01</td>
    ///         <td style="width: 8%">PHYS130093h</td>
    ///         <td style="width: 18%">
    ///             大学物理A：原子物理(H)
    ///         </td>
    ///         <td style="width: 8%">期末考试</td>
    ///         <td style="width: 11%">
    ///             2024-06-21
    ///         </td>
    ///         <td style="width: 12%">
    ///             13:00~15:00
    ///         </td>
    ///         <td style="width: 8%">
    ///             H3209
    ///         </td>
    ///         <td style="width: 6%">
    ///             闭卷
    ///         </td>
    ///         <td style="width: 8%">
    ///         </td>
    ///     </tr>
    ///     <tr>
    ///         <td style="width: 10%">MATH120022.04</td>
    ///         <td style="width: 8%">MATH120022</td>
    ///         <td style="width: 18%">
    ///             高等数学A(下）
    ///         </td>
    ///         <td style="width: 8%">期末考试</td>
    ///         <td style="width: 11%">
    ///             2024-06-21
    ///         </td>
    ///         <td style="width: 12%">
    ///             08:30~10:30
    ///         </td>
    ///         <td style="width: 8%">
    ///             H3208
    ///         </td>
    ///         <td style="width: 6%">
    ///             闭卷
    ///         </td>
    ///         <td style="width: 8%">
    ///         </td>
    ///     </tr>
    ///     <tr style="color:#BBC4C3;">
    ///         <td style="width: 10%">ENGL110057.02</td>
    ///         <td style="width: 8%">ENGL110057</td>
    ///         <td style="width: 18%">
    ///             英国文学欣赏指南
    ///         </td>
    ///         <td style="width: 8%">期末考试</td>
    ///         <td style="width: 11%">
    ///             2024-06-14
    ///
    ///         </td>
    ///         <td style="width: 12%">
    ///             19:50~21:00
    ///
    ///         </td>
    ///         <td style="width: 8%">
    ///             H2201
    ///
    ///         </td>
    ///         <td style="width: 6%">
    ///             闭卷
    ///
    ///
    ///         </td>
    ///         <td style="width: 8%">
    ///
    ///
    ///         </td>
    ///     </tr>
    ///     <tr>
    ///         <td style="width: 10%">PHYS130013.01</td>
    ///         <td style="width: 8%">PHYS130013</td>
    ///         <td style="width: 18%">
    ///             毕业论文
    ///         </td>
    ///         <td style="width: 8%">无</td>
    ///         <td style="width: 11%">
    ///             2024-06-08
    ///         </td>
    ///         <td style="width: 12%">
    ///             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;~18:30
    ///         </td>
    ///         <td style="width: 8%">
    ///             <font color="BBC4C3">无</font>
    ///         </td>
    ///         <td style="width: 6%">
    ///             论文
    ///         </td>
    ///         <td style="width: 8%">
    ///
    ///
    ///         </td>
    ///     </tr>
    ///     <tr style="color:#BBC4C3;">
    ///         <td style="width: 10%">MATH120022.04</td>
    ///         <td style="width: 8%">MATH120022</td>
    ///         <td style="width: 18%">
    ///             高等数学A(下）
    ///         </td>
    ///         <td style="width: 8%">期中考试</td>
    ///         <td style="width: 11%">
    ///             <font color="BBC4C3">无</font>
    ///
    ///         </td>
    ///         <td style="width: 12%">
    ///             <font color="BBC4C3">无</font>
    ///
    ///         </td>
    ///         <td style="width: 8%">
    ///             <font color="BBC4C3">无</font>
    ///         </td>
    ///         <td style="width: 6%">
    ///             闭卷
    ///         </td>
    ///         <td style="width: 8%">
    ///         </td>
    ///     </tr>
    /// </table>
    /// ```
    public static func getExams() async throws -> [Exam] {
        let url = URL(string: "https://jwfw.fudan.edu.cn/eams/stdExamTable!examTable.action")!
        let data = try await Authenticator.shared.authenticate(url, manualLoginURL: loginURL)
        
        var exams: [Exam] = []
        
        let elements = try decodeHTMLElementList(data, selector: "tr")
        for element in elements {
            let cells = try element.select("td")
            
            // table header is passed
            if cells.isEmpty() {
                continue
            }
            
            var courseId = ""
            var course = ""
            var type = ""
            var method = ""
            var date = ""
            var time = ""
            var location = ""
            var note = ""
            
            for (index, cell) in cells.enumerated() {
                let text = try cell.text(trimAndNormaliseWhitespace: true) // TODO: remove entities like &nbsp
                
                switch index {
                case 0:
                    courseId = text
                case 2:
                    course = text
                case 3:
                    type = text
                case 4:
                    date = text
                case 5:
                    time = text
                case 6:
                    location = text
                case 7:
                    method = text
                case 8:
                    note = text
                default:
                    continue
                }
            }
            
            let exam = Exam(id: UUID(), courseId: courseId, course: course, type: type, method: method, date: date, time: time, location: location, note: note)
            exams.append(exam)
        }
        
        return exams
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
