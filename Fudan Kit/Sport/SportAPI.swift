import Foundation
import SwiftSoup
import Utils

/// API collection for student sports
///
/// - Important:
///        Call ``login()`` before invoking any API
public enum SportAPI {
    static let loginURL = URL(string: "http://tac.fudan.edu.cn/thirds/tjb.act?redir=sportScore")!
    
    /// Get exercise
    /// - Returns: A tuple, including the count of each exercise category and exercise logs.
    public static func getExercise() async throws -> ([Exercise], [ExerciseLog]) {
        let exerciseURL = URL(string: "https://fdtyjw.fudan.edu.cn/sportScore/stscore.aspx?item=1")!
        let data = try await Authenticator.classic.authenticate(exerciseURL, loginURL: loginURL)
        
        let exercises = try parseExercise(data: data)
        if let logs = try? parseExerciseLog(data: data) {
            return (exercises, logs)
        }
        
        // fail-safe, user can still view exercise info when exercise logs are not available
        return (exercises, [])
    }
    
    // TODO: Documentation
    private static func parseExercise(data: Data) throws -> [Exercise] {
        let element = try decodeHTMLElement(data, selector: "#pitem > table > tbody > tr:nth-of-type(4) > td > table > tbody")
        
        var exercises: [Exercise] = []
        
        for row in element.children() {
            let count = row.childNodeSize()
            for i in stride(from: 0, to: count, by: 2) {
                do {
                    var category = try row.child(i).html()
                    category.removeLast(1) // remove "："
                    if i + 1 >= count { return exercises } // prevent overflow before accessing `child(i + 1)`
                    guard let exerciseCount = Int(try row.child(i + 1).html()) else {
                        continue
                    }
                    let exercise = Exercise(id: UUID(), category: category, count: exerciseCount)
                    exercises.append(exercise)
                } catch {
                    continue
                }
            }
        }
        
        return exercises
    }
    
    // TODO: Documentation
    private static func parseExerciseLog(data: Data) throws -> [ExerciseLog] {
        let element = try decodeHTMLElement(data, selector: "#pitem > table > tbody > tr:nth-of-type(7) > td > table > tbody")
        
        var logs: [ExerciseLog] = []
        
        for row in element.children() {
            // prevent out-of-bound error
            guard row.childNodeSize() > 4 else {
                throw LocatableError()
            }
            
            do {
                let category = try row.child(1).html()
                let date = try row.child(2).html()
                var time = try row.child(3).html()
                let status = try row.child(4).html()
                
                // filter "--" from time string
                let pattern = #/
                (?<time> \d+:\d+)
                *
                /#
                if let timeStr = time.firstMatch(of: pattern)?.time {
                    time = String(timeStr)
                }
                
                let log = ExerciseLog(id: UUID(), category: category, date: "\(date) \(time)", status: status)
                logs.append(log)
            } catch {
                continue
            }
        }
        
        return logs
    }
    
    
    /// Get exam data, including score, items and logs.
    public static func getExam() async throws -> SportExam {
        let examURL = URL(string: "https://fdtyjw.fudan.edu.cn/sportScore/stScore.aspx?item=3")!
        let data = try await Authenticator.classic.authenticate(examURL, loginURL: loginURL)
        
        let document = try decodeHTMLDocument(data)
        
        guard let totalText = try document.select("#pitem > table > tbody > tr:nth-child(4) > td > table > tbody > tr:nth-child(11) > td:nth-child(3) > red").first(),
              let total = Double(try totalText.html()) else {
            throw LocatableError()
        }
        
        guard let evaluation = try document.select("#pitem > table > tbody > tr:nth-child(4) > td > table > tbody > tr:nth-child(11) > td:nth-child(5) > red").first()?.html() else {
            throw LocatableError()
        }
        
        let items = try getExamItems(document: document)
        let logs = try getExamLogs(document: document)
        return SportExam(total: total, evaluation: evaluation, items: items, logs: logs)
    }
    
    // TODO: Documentation
    private static func getExamItems(document: Document) throws -> [SportExamItem] {
        var items: [SportExamItem] = []
        
        guard let itemsTable = try document.select("#pitem > table > tbody > tr:nth-child(4) > td > table > tbody").first() else {
            return []
        }
        
        guard itemsTable.childNodeSize() > 5 else {
            return []
        }
        
        for i in 0...6 {
            do {
                let row = itemsTable.child(i)
                if row.childNodeSize() > 4 {
                    let name = try row.child(1).html()
                    let result = try row.child(2).html()
                    let scoreText = try row.child(3).html()
                        .components(separatedBy: CharacterSet.decimalDigits.inverted).joined()  // filter non-digits
                    guard let score = Int(scoreText) else { continue }
                    let status = try row.child(4).html().replacingOccurrences(of: " &nbsp;", with: "")
                    let item = SportExamItem(id: UUID(), name: name, result: result, score: score, status: status)
                    items.append(item)
                }
            } catch {
                continue
            }
        }
        
        return items
    }
    
    // TODO: Documentation
    private static func getExamLogs(document: Document) throws -> [SportExamLog] {
        var logs: [SportExamLog] = []
        
        guard let itemsTable = try document.select("#pitem > table > tbody > tr:nth-child(11) > td > table > tbody").first() else {
            return []
        }
        
        for row in itemsTable.children() {
            do {
                let name = try row.child(1).html()
                let date = try row.child(3).html()
                let result = try row.child(4).html()
                
                let log = SportExamLog(id: UUID(), name: name, date: date, result: result)
                logs.append(log)
            } catch {
                continue
            }
        }
        
        return logs
    }
}
