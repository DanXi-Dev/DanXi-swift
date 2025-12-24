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
    ///
    private struct CourseBuilder: Codable {
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

    public static func getCourses(semesterId: Int) async throws -> [Course] {
        let url = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/course-table/semester/\(semesterId)/print-data")!
        let data = try await Authenticator.neo.authenticate(url, loginURL: loginURL)
        let json = try JSON(data: data)
        let coursesData = try json["studentTableVms"][0]["activities"].rawData()
        
        let courseBuilders = try JSONDecoder().decode([CourseBuilder].self, from: coursesData)
        
        return mergeCourseBuilders(courseBuilders)
    }

    // Solve the scheduling for courses that change rooms or teachers weekly
    /// When the same course is taught in multiple classrooms or by multiple teachers, the fdjwgl system's json file treats them as separate courses. Therefore, it's necessary to merge the classroom or teacher information; otherwise, this will result in overlapping courses on the calendar.
    ///
    /// Sketched out next is an example:
    /// {"lessonId":720500,"lessonCode":"COMP130135.03","lessonName":"全校13","courseCode":"CS20012","courseName":"面向对象程序设计","weeksStr":"2~16(双)","weekIndexes":[16,2,4,6,8,10,12,14],"room":"H逸夫楼204","building":"H逸夫楼","campus":"邯郸校区","weekday":3,"startUnit":6,"endUnit":7,"lessonRemark":null,"teachers":["王雪平"],"courseType":{"nameZh":"专业教育课程","nameEn":"id:5","id":3,"code":"03","enabled":false,"createdDateTime":null,"updatedDateTime":null,"bizTypeAssocs":[2,3,4],"transient":false,"bizTypeIds":[4,2,3],"name":"专业教育课程"},"credits":2.0,"periodInfo":{"total":36.0,"weeks":18,"theory":36.0,"theoryUnit":null,"requireTheory":null,"practice":null,"practiceUnit":null,"requirePractice":null,"focusPractice":null,"focusPracticeUnit":null,"dispersedPractice":null,"test":null,"testUnit":null,"requireTest":null,"experiment":null,"experimentUnit":null,"requireExperiment":null,"machine":null,"machineUnit":null,"requireMachine":null,"design":null,"designUnit":null,"requireDesign":null,"periodsPerWeek":2.0,"extra":null,"extraUnit":null,"requireExtra":null},"stdCount":88,"limitCount":99,"startTime":"13:30","endTime":"15:10","groupNum":null,"semesterId":null,"activityType":null,"taskPeopleNum":null},{"lessonId":720500,"lessonCode":"COMP130135.03","lessonName":"全校13","courseCode":"CS20012","courseName":"面向对象程序设计","weeksStr":"2~16(双)","weekIndexes":[16,2,4,6,8,10,12,14],"room":"H逸夫楼205","building":"H逸夫楼","campus":"邯郸校区","weekday":3,"startUnit":6,"endUnit":7,"lessonRemark":null,"teachers":["王雪平"],"courseType":{"nameZh":"专业教育课程","nameEn":"id:5","id":3,"code":"03","enabled":false,"createdDateTime":null,"updatedDateTime":null,"bizTypeAssocs":[2,3,4],"transient":false,"bizTypeIds":[4,2,3],"name":"专业教育课程"},"credits":2.0,"periodInfo":{"total":36.0,"weeks":18,"theory":36.0,"theoryUnit":null,"requireTheory":null,"practice":null,"practiceUnit":null,"requirePractice":null,"focusPractice":null,"focusPracticeUnit":null,"dispersedPractice":null,"test":null,"testUnit":null,"requireTest":null,"experiment":null,"experimentUnit":null,"requireExperiment":null,"machine":null,"machineUnit":null,"requireMachine":null,"design":null,"designUnit":null,"requireDesign":null,"periodsPerWeek":2.0,"extra":null,"extraUnit":null,"requireExtra":null},"stdCount":88,"limitCount":99,"startTime":"13:30","endTime":"15:10","groupNum":null,"semesterId":null,"activityType":null,"taskPeopleNum":null},
    ///
    /// We want the final display to show one course with its room as 'H逸夫楼 204, H逸夫楼 205', rather than showing two separate courses in different classrooms.
    
    private static func mergeCourseBuilders(_ builders: [CourseBuilder]) -> [Course] {
        var courseDict = [String: Course]()
        
        func mergeProperties(from old: String, and new: String) -> String {
            let oldItems = Set(old.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
            let newItems = Set(new.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                
            return Array(oldItems.union(newItems))
                .filter { !$0.isEmpty }
                .sorted()
                .joined(separator: ", ")
        }
        
        var coursesToSplit = Set<String>()
        
        let courses = builders.map { $0.build() }
        
        for course in courses {
            if courses.contains(where: { $0.code == course.code && $0.conflicts(with: course) }) {
                coursesToSplit.insert(course.code)
            }
        }
        
        for builder in builders {
            var courses : [Course] = []
            if coursesToSplit.contains(builder.lessonCode) {
                let template = builder.build()
                courses = template.onWeeks.map{ week in
                    Course(id: UUID(), name: template.name, code: template.code, teacher: template.teacher, location: template.location, weekday: template.weekday, start: template.start, end: template.end, onWeeks: [week])
                }
            }
            else{
                courses = [builder.build()]
            }
            
            for course in courses {
                let weeksKey = course.onWeeks.sorted().map(String.init).joined(separator: "_")
                let key = "\(course.code)-\(course.weekday)-\(course.start)-\(course.end)-\(weeksKey)"
                
                if let existed = courseDict[key] {
                    let mergedRooms = mergeProperties(from: existed.location, and: course.location)
                    let mergedTeachers = mergeProperties(from: existed.teacher, and: course.teacher)
                    
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
        }

        return Array(courseDict.values)
    }
    // MARK: - Exam
    
    /// Get user's exam list
    ///
    /// ## API Detail
    ///
    /// This API uses the neo authentication to fetch exam information from the new endpoint.
    /// The new endpoint returns HTML with an exam table.
    ///
    /// - Returns: A list of ``Exam``, including both finished and upcoming exams
    ///
    /// Exam status:
    /// - Exams with class "finished hide" are completed exams
    /// - Exams with class "unfinished" are upcoming/pending exams
    ///
    /// ## Example HTML Response:
    /// ```html
    /// <tr data-finished="false" class="unfinished">
    ///     <td>
    ///         <div class="time">2026-01-04 08:30~10:30</div>
    ///         <div>
    ///             <span>邯郸校区</span>
    ///             <span>H邯郸校区第六教学楼</span>
    ///             <span>H6506</span>
    ///         </div>
    ///     </td>
    ///     <td>
    ///         <div>
    ///             <span>数字集成电路设计原理(H) </span>
    ///             <span>ICSE30021h.01 </span>
    ///             <span>（闭卷） </span>
    ///         </div>
    ///         <div>
    ///             <span class="tag-span type2">期末</span>
    ///         </div>
    ///     </td>
    ///     <td>请携带学生证或一卡通，待考试时核查。</td>
    ///     <td>未结束</td>
    /// </tr>
    /// <tr data-finished="true" class="finished hide">
    ///     <td>
    ///         <div class="time ">2025-11-11 13:00~15:00</div>
    ///         <div>
    ///             <span>邯郸校区</span>
    ///             <span>H邯郸校区第二教学楼</span>
    ///             <span>H2115</span>
    ///         </div>
    ///     </td>
    ///     <td>
    ///         <div>
    ///             <span>半导体器件原理(H) </span>
    ///             <span>ICSE30020h.01 </span>
    ///             <span>（半开卷） </span>
    ///         </div>
    ///         <div>
    ///             <span class="tag-span type1">期中</span>
    ///         </div>
    ///     </td>
    ///     <td>请携带学生证或一卡通，待考试时核查。</td>
    ///     <td>已结束</td>
    /// </tr>
    /// ```
    public static func getExams() async throws -> [Exam] {
        let studentId = try await getStudentId()
        let url = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/exam-arrange/info/\(studentId)")!
        let data = try await Authenticator.neo.authenticate(url, loginURL: loginURL)

        var exams: [Exam] = []

        let elements = try decodeHTMLElementList(data, selector: "table.exam-table tbody tr")
        for element in elements {
            let classAttr = try? element.attr("class")
            if let classAttr = classAttr, classAttr.contains("tr-empty") {
                continue
            }

            let cellsArray = try element.select("td").array()
            guard cellsArray.count >= 4 else {
                continue
            }

            var courseId = ""
            var course = ""
            var type = ""
            var method = ""
            var semester = ""
            var date = ""
            var time = ""
            var location = ""
            var note = ""
            var isFinished = false

            let dataFinishedAttr = try? element.attr("data-finished")
            if let dataFinishedAttr = dataFinishedAttr, dataFinishedAttr == "true" {
                isFinished = true
            }

            let firstCell = cellsArray[0]
            if let timeDiv = try? firstCell.select("div.time").first(),
               let timeText = try? timeDiv.text(trimAndNormaliseWhitespace: true) {
                let timeComponents = timeText.components(separatedBy: " ")
                if timeComponents.count >= 2 {
                    semester = timeComponents[0]
                    date = timeComponents[1]
                    time = timeComponents[2]
                }

                if let spanArray = try? firstCell.select("span").array(),
                   spanArray.count > 2 {
                    location = (try? spanArray[2].text(trimAndNormaliseWhitespace: true)) ?? ""
                }
            }

            // Course information
            let secondCell = cellsArray[1]
            if let firstDiv = try? secondCell.select("div").first(),
               let spans = try? firstDiv.select("span").array(),
               spans.count >= 3 {
                course = (try? spans[0].text(trimAndNormaliseWhitespace: true)) ?? ""
                courseId = (try? spans[1].text(trimAndNormaliseWhitespace: true)) ?? ""

                if let methodText = try? spans[2].text(trimAndNormaliseWhitespace: true),
                   methodText.hasPrefix("（"), methodText.hasSuffix("）") {
                    method = String(methodText.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                }
            }

            // Exam type
            if let divs = try? secondCell.select("div").array(),
               divs.count >= 2,
               let typeSpan = try? divs[1].select("span").first(),
               let typeText = try? typeSpan.text(trimAndNormaliseWhitespace: true) {
                type = typeText.trimmingCharacters(in: .whitespaces)
            }
            if type.isEmpty { type = "无" }

            note = (try? cellsArray[2].text(trimAndNormaliseWhitespace: true)) ?? ""

            let exam = Exam(id: UUID(), courseId: courseId, course: course, type: type, method: method, semester: semester, date: date, time: time, location: location, note: note, isFinished: isFinished)
            exams.append(exam)
        }

        return exams
    }
    
    // MARK: - Score and GPA

    /// Get  student ID from course table API
    private static func getStudentId() async throws -> String {
        let (_, semesterId) = try await getSemesters()

        let url = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/course-table/semester/\(semesterId)/print-data")!
        let data = try await Authenticator.neo.authenticate(url, loginURL: loginURL)
        let json = try JSON(data: data)

        guard let studentId = json["studentTableVms"][0]["id"].int else {
            throw LocatableError()
        }

        return String(studentId)
    }

    /// Get the student course score on a given semeser
    /// - Parameter semester: Semester ID
    /// - Returns: A list of ``Score``
    public static func getScore(semester: Int) async throws -> [Score] {
        let studentId = try await getStudentId()

        let url = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/grade/sheet/info/\(studentId)?semester=\(semester)")!
        let data = try await Authenticator.neo.authenticate(url, loginURL: loginURL)

        let json = try JSON(data: data)
        let semesterKey = String(semester)
        guard let gradesArray = json["semesterId2studentGrades"][semesterKey].array else {
            return []
        }

        var scores: [Score] = []
        for gradeJson in gradesArray {
            guard let gradeData = try? gradeJson.rawData() else { continue }
            let decoder = JSONDecoder()
            if let scoreResponse = try? decoder.decode(ScoreResponse.self, from: gradeData) {
                var courseTypeText = scoreResponse.courseModuleTypeName ?? scoreResponse.courseType ?? ""
                if let commaIndex = courseTypeText.firstIndex(of: ",") {
                    courseTypeText = String(courseTypeText[..<commaIndex])
                }

                let score = Score(
                    id: UUID(),
                    courseId: scoreResponse.lessonCode,
                    courseName: scoreResponse.courseName,
                    courseType: courseTypeText,
                    courseCredit: nil,
                    grade: scoreResponse.gaGrade,
                    gradePoint: scoreResponse.gp != nil ? String(format: "%.2f", scoreResponse.gp!) : ""
                )
                scores.append(score)
            }
        }

        return scores
    }

    private struct ScoreResponse: Decodable {
        let lessonCode: String
        let courseCode: String
        let courseName: String
        let courseType: String?
        let courseModuleTypeName: String?
        let gaGrade: String
        let gp: Double?
    }
    
    /// Get the rank list, aka GPA ranking table (department-wide ranking)
    public static func getRanks() async throws -> [Rank] {
        let studentId = try await getStudentId()
        
        // Get departmentAssoc and grade from search-index page
        let indexURL = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/grade/my-gpa/search-index/\(studentId)")!
        let indexData = try await Authenticator.neo.authenticate(indexURL, loginURL: loginURL)
        
        guard let html = String(data: indexData, encoding: .utf8),
              let gradeMatch = html.firstMatch(of: /name="grade"\s+value="(\d+)"/),
              let deptMatch = html.firstMatch(of: /name="departmentAssoc"\s+value="(\d+)"/) else {
            throw LocatableError()
        }
        
        // get department GPA ranks
        let searchURL = URL(string: "https://fdjwgl.fudan.edu.cn/student/for-std/grade/my-gpa/search?studentAssoc=\(studentId)&grade=\(gradeMatch.1)&departmentAssoc=\(deptMatch.1)&majorAssoc=")!
        let searchData = try await Authenticator.neo.authenticate(searchURL, loginURL: loginURL)
        
        guard let ranksArray = try JSON(data: searchData)["data"].array else {
            return []
        }
        
        return ranksArray.compactMap { rankJson -> Rank? in
            guard let name = rankJson["name"].string,
                  let grade = rankJson["grade"].string,
                  let major = rankJson["major"].string,
                  let department = rankJson["department"].string,
                  let gpa = rankJson["gpa"].double,
                  let credit = rankJson["credit"].double,
                  let ranking = rankJson["ranking"].int else {
                return nil
            }
            return Rank(id: UUID(), name: name, grade: grade, major: major, department: department, gradePoint: gpa, credit: credit, rank: ranking)
        }
    }
}
