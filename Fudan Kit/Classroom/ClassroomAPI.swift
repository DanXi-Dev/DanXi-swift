import Foundation
import SwiftSoup

/// API collection that shows classroom occupation status.
///
/// This API uses data from `http://10.64.130.6/`, which can only be accessed in campus.
/// To enable users to view course schedules anywhere, we use WebVPN service to access this service
/// outside campus.
public enum ClassroomAPI {
    /// Get classroom and schedules in the given building.
    ///
    /// ## API Detail
    ///
    /// The server respond with the following HTML structure:
    /// ```html
    /// <table id="statusTable_0">
    ///     first 3 rows are table header, useless
    ///
    ///     <tr>
    ///         <td>
    ///             ... multiple tags
    ///                         <td align=center><a id="rt379">H2101</a></td>
    ///         </td>
    ///
    ///         <td style="background-color:white;text-align:center">
    ///             ... multiple tags
    ///             <span>234</span> /// classroom capacity, ignored
    ///         </td>
    ///
    ///         <td></td>
    ///
    ///         <td></td>
    ///
    ///         <td>
    ///             <span class=tag>
    ///                 <span class='rare'>本</span>
    ///             </span>
    ///             PTSS110088<font> </font>.<font> </font>07<br>[中国近现代史纲要](梁君思){119人}<br> // both teacher and capacity are optional
    ///         </td>
    ///
    ///         (repeated for 3 times)
    ///
    ///         (expections: )
    ///         <td>
    ///             <span class=tag>
    ///                 <span>
    ///                     <font color=red>临借</font>
    ///                 </span>
    ///             </span>
    ///             35396 国务学院2023级本科生班第二次班会课 <br>
    ///         </td>
    ///     </tr>
    /// </table>
    /// ```
    public static func getClassrooms(building: Building) async throws -> [Classroom] {
        // get data from server
        var component = URLComponents(string: "https://webvpn.fudan.edu.cn/http/77726476706e69737468656265737421a1a70fca737e39032e46df/")!
        component.queryItems = [URLQueryItem(name: "b", value: building.rawValue)]
        let url = component.url!
        let data = try await Authenticator.shared.authenticate(url, manualLoginURL: URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!)
        
        var classrooms: [Classroom] = []
        
        // parse classrooms
        let table = try decodeHTMLElement(data, selector: "#statusTable_0")
        
        let rows = table.children().first()!.children()
            .filter { $0.tagName() == "tr" }.dropFirst(3)
        for row in rows {
            // parse classroom information
            
            guard let nameElement = try row.getElementsByTag("a").first(),
                  let name = try? nameElement.text() else {
                continue
            }
            
            guard let capacityElement = try row.getElementsByTag("span").first(),
                  let capacity = try? capacityElement.text() else {
                continue
            }
            
            // parse schedules
            
            var schedules: [CourseSchedule] = []
            var scheduleBuilder: CourseScheduleBuilder?
            let children = row
                .children()
                .filter({ $0.tagName() == "td" })
                .dropFirst(2)
            
            for (idx, child) in children.enumerated() {
                if let builder = try parseCourseSchedule(element: child, idx: idx) {
                    if builder.name == scheduleBuilder?.name {
                        scheduleBuilder?.end += 1
                    } else {
                        if let scheduleBuilder = scheduleBuilder {
                            let schedule = scheduleBuilder.build()
                            schedules.append(schedule)
                        }
                        scheduleBuilder = builder
                    }
                }
            }
            
            // last item problem
            if let scheduleBuilder = scheduleBuilder {
                let schedule = scheduleBuilder.build()
                schedules.append(schedule)
            }
            
            let classroom = Classroom(id: UUID(), name: name, capacity: capacity, schedules: schedules)
            classrooms.append(classroom)
        }
        
        return classrooms
    }
    
    private static func parseCourseSchedule(element: Element, idx: Int) throws -> CourseScheduleBuilder? {
        let category = try? element.select(".rare").first()?.text()
        
        // remove category tag
        try element.select("span").remove()
        
        // get and parse font
        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let texts = text.split(separator: " ")
        
        if text.isEmpty { return nil }
        
        // builder that should be returned when parsing fails (which means an exception)
        let failedBuilder = CourseScheduleBuilder(name: text, courseId: "", category: nil, teacher: nil, capacity: nil, start: idx, end: idx)
        
        guard texts.count >= 4 else {
            return failedBuilder
        }
        
        let pattern = /\[(?<name>[^\]]+)\](\((?<teacher>[^\)]+)\))?(\{(?<capacity>[^\}]+)\})?/
        let courseId = String(texts[0] + texts[1] + texts[2])
        guard let match = texts[3].firstMatch(of: pattern) else {
            return failedBuilder
        }
        let name = String(match.name)
        var teacher: String?
        if let teacherMatch = match.teacher {
            teacher = String(teacherMatch)
        }
        var capacity: String?
        if let capacityMatch = match.capacity {
            capacity = String(capacityMatch)
        }
        
        return CourseScheduleBuilder(name: name, courseId: courseId, category: category, teacher: teacher, capacity: capacity, start: idx, end: idx)
    }
    
    /// Course schedule will be processed in multiple iterations.
    /// This struct is to help this process, while allowing the properties in
    /// ``CourseSchedule`` to remain constant
    private struct CourseScheduleBuilder {
        let id = UUID()
        let name: String
        let courseId: String
        let category: String?
        let teacher: String?
        let capacity: String?
        let start: Int
        var end: Int
        
        func build() -> CourseSchedule {
            return CourseSchedule(id: id, start: start, end: end, name: name, courseId: courseId, category: category, teacher: teacher, capacity: capacity)
        }
    }
}
