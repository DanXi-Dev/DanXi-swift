import Foundation
import SwiftSoup

struct FDClassroomAPI {    
    static func getClassrooms(building: FDBuilding) async throws -> [FDClassroom] {
        var component = URLComponents(string: "https://webvpn.fudan.edu.cn/http/77726476706e69737468656265737421a1a70fca737e39032e46df/")!
        component.queryItems = [URLQueryItem(name: "b", value: building.rawValue)]
        let url = component.url!
        let request = prepareRequest(url)
        let (data, _) = try await sendRequest(request)
        let table = try processHTMLData(data, selector: "#statusTable_0 > tbody")
        return try parseTable(table: table)
    }

    private static func parseTable(table: Element) throws -> [FDClassroom] {
        var classrooms: [FDClassroom] = []
        let rows = table.children().filter { $0.tagName() == "tr" }
        for i in 3..<rows.count {
            if let classroom = try? parseRow(element: rows[i]) {
                classrooms.append(classroom)
            }
        }
        return classrooms
    }
    
    private static func parseRow(element: Element) throws -> FDClassroom {
        var classroom = FDClassroom()
        let children = element.children()
        let cells = children.filter { $0.tagName() == "td" }
        for i in 0..<cells.count {
            let cell = cells[i]
            if i == 0 {
                // first cell, classroom name
                let name = try parseClassroomName(element: cell)
                classroom.name = name
            } else if i == 1 {
                // second cell, classroom capacity
                let capacity = try parseClassroomCapacity(element: cell)
                classroom.capacity = capacity
            } else {
                // courses or empty cell
                if !isBlankCell(element: cell) {
                    var event = try parseCourse(element: cell)
                    
                    // merge duplicate courses
                    if (classroom.courses.last?.courseId != nil) && // if this condition is met, it is guaranteed that classrooms has last element, and it's id is not nil, so it's safe to force unwrap
                       (!classroom.courses.last!.courseId!.isEmpty) &&
                       (classroom.courses.last!.courseId! == event.courseId) {
                        let lastIdx = classroom.courses.count - 1
                        classroom.courses[lastIdx].end = i - 2
                    } else {
                        event.start = i - 2
                        event.end = i - 2
                        classroom.courses.append(event)
                    }
                }
            }
        }
        return classroom
    }
    
    private static func parseClassroomName(element: Element) throws -> String {
        guard let link = try element.getElementsByTag("a").first() else {
            throw ParseError.invalidHTML
        }
        let room = try link.text()
        return room
    }
    
    private static func parseClassroomCapacity(element: Element) throws -> String {
        guard let span = try element.getElementsByTag("span").first() else {
            throw ParseError.invalidHTML
        }
        let capacity = try span.text()
        return capacity
    }
    
    private static func isBlankCell(element: Element) -> Bool {
        guard let content = try? element.html() else { return true }
        return content.isEmpty
    }
    
    private static func parseCourse(element: Element) throws -> FDEvent {
        var event = FDEvent()
        
        // parse category
        if let category = try? element.select(".rare").first(),
           let categoryText = try? category.text() {
            event.category = categoryText
        }
        
        // remove unnecessary tags
        try element.select(".tag").remove()
        try element.select(".font").remove()
        
        // get texts
        let textNodes = element.textNodes()
        let texts = textNodes.map { $0.text().trimmingCharacters(in: .whitespacesAndNewlines) }
                             .filter { !$0.isEmpty }
        guard texts.count > 3 else {
            throw ParseError.invalidHTML
        }
        
        // parse ID
        let id = texts[0] + texts[1] + texts[2]
        event.courseId = id
        
        // parse name
        var courseInfo = ""
        for i in 3..<texts.count {
            courseInfo += texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let match = courseInfo.firstMatch(of: /\[(?<name>[^\]]+)\](\((?<teacher>[^\)]+)\))?(\{(?<count>[^\}]+)\})?/) {
            event.name = String(match.name)
            if let teacher = match.teacher {
                event.teacher = String(teacher)
            }
            if let count = match.count {
                event.count = String(count)
            }
        } else {
            event.name = courseInfo
        }
        
        return event
    }
}

// MARK: - Model

enum FDBuilding: String {
    case empty = ""
    case h2 = "H2"
    case h3 = "H3"
    case h4 = "H4"
    case h5 = "H5"
    case h6 = "H6"
    case hgx = "HGX"
    case hgd = "HGD"
    case hq = "HQ"
    case j = "J"
    case z = "Z"
    case f = "F"
}

struct FDClassroom {
    var name = ""
    var capacity = ""
    var courses: [FDEvent] = []
}

struct FDEvent: Identifiable {
    let id = UUID()
    var start = 0
    var end = 0
    var name: String = ""
    var courseId: String?
    var category: String?
    var teacher: String?
    var count: String?
}
