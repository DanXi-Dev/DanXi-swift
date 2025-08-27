import Foundation
import SwiftyJSON
import Utils

/// API collection for academic and courses service.
/// These API are only available to undergraduate students.
public enum UndergraduateCourseAPI {
    
    // MARK: Login
    
    static let loginURL = URL(string: "https://fdjwgl.fudan.edu.cn/student/sso/login")!
    
    // MARK: - Courses
    
    /// Get all semesters from server
    ///
    /// - Returns:
    ///      A list of semesters and the current semester ID
    public static func getSemesters() async throws -> ([Semester], Int) {
        let url = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/course-table")!
        let data = try await Authenticator.neo.authenticate(url, loginURL: loginURL)
        let elements = try decodeHTMLElementList(data, selector: "option[value]")
        
        let semesters: [Semester] = elements
            .compactMap { element -> (id: Int, text: String)? in
                guard let value = try? element.attr("value"),
                      let id = Int(value),
                      let text = try? element.text() else {
                    return nil
                }
                
                return (id, text)
            }
            // remove duplication by id
            .reduce(into: [Int: String]()) { acc, pair in
                acc[pair.id] = acc[pair.id] ?? pair.text
            }
            .compactMap { id, text in
                guard let yearStr = text.firstMatch(of: /(\d{4})-\d{4}/)?.1,
                      let year    = Int(yearStr)
                else { return nil }
                
                let type: Semester.SemesterType =
                    if text.contains("1学期")      { .first  }
                    else if text.contains("2学期") { .second }
                    else if text.contains("暑")    { .summer }
                    else if text.contains("寒")    { .winter }
                    else                          { .first }
                
                return Semester(year: year,
                                type: type,
                                semesterId: id,
                                startDate: nil,
                                weekCount: 18)
            }
            .sorted { ($0.year, $0.type.rawValue) > ($1.year, $1.type.rawValue) }
        
        guard let html = String(data: data, encoding: .utf8) else { throw LocatableError() }
        let semesterIdPattern = /'id':\s*"?(?<semester>\d{3,})"?/
        guard let semesterStr = html.firstMatch(of: semesterIdPattern)?.semester,
              let semesterId  = Int(semesterStr) else {
            throw LocatableError()
        }
  
        return (semesters, semesterId)
    }
    
    /// Get course table for undergraduate
    /// - Parameters:
    ///   - semesterId: semester ID
    /// - Returns: A list of ``Course``, representing student course table
    public static func getCourses(semesterId: Int) async throws -> [Course] {
        let url = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/course-table/semester/\(semesterId)/print-data")!
        let data = try await Authenticator.neo.authenticate(url, loginURL: loginURL)
        let json = try JSON(data: data)
        let coursesData = try json["studentTableVms"][0]["activities"].rawData()
        
        struct CourseBuilder: Codable {
            let lessonCode, courseName: String
            let room: String?
            let teachers: [String]
            let startUnit, endUnit, weekday: Int
            let weekIndexes: [Int]
            
            func build() -> Course {
                Course(id: UUID(),
                       name: courseName,
                       code: lessonCode,
                       teacher: teachers.first ?? "",
                       location: room ?? "",
                       weekday: weekday - 1,
                       start: startUnit - 1,
                       end: endUnit - 1,
                       onWeeks: weekIndexes)
            }
        }
        
        return try JSONDecoder().decode([CourseBuilder].self, from: coursesData)
            .map { $0.build() }
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
        let data = try await Authenticator.classic.authenticate(url, loginURL: loginURL)
        
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
        let data = try await Authenticator.classic.authenticate(url, loginURL: loginURL)
        
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
        let data = try await Authenticator.classic.authenticate(url, loginURL: loginURL)
        
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
