import Foundation
import SwiftyJSON

struct FDAcademicRequests {
    static func login() async throws {
        let loginURL = URL(string: "http://jwfw.fudan.edu.cn/eams/home.action")!
        _ = try await FudanAuthRequests.auth(url: loginURL)
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
            let score = FDScore(courseId: try row.child(2).html(),
                                name: try row.child(3).html(),
                                type: try row.child(4).html(),
                                credit: try row.child(5).html(),
                                grade: try row.child(6).html(),
                                gradePoint: try row.child(7).html())
            scoreList.append(score)
        }
        
        return scoreList
    }
}

struct FDSemester: Codable, Identifiable {
    let id: Int
    let schoolYear: String
    let name: String
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
