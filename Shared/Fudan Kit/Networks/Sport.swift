import Foundation
import SwiftSoup

// MARK: - Request

struct SportRequest {
    
    static func login() async throws {
        let loginURL = URL(string: "http://tac.fudan.edu.cn/thirds/tjb.act?redir=sportScore")!
        _ = try await FudanAuthRequests.auth(url: loginURL)
    }
    
    static func fetchExerciseData() async throws -> ExerciseInfo {
        let exerciseURL = URL(string: "https://fdtyjw.fudan.edu.cn/sportScore/stscore.aspx?item=1")!
        let request = URLRequest(url: exerciseURL)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let htmlText = String(data: data, encoding: String.Encoding.utf8) else {
            throw NetworkError.invalidResponse
        }
        let doc = try SwiftSoup.parse(htmlText)
        var info = ExerciseInfo()
        info.parseExerciseItems(doc)
        info.parseExerciseLogs(doc)
        return info
    }
    
    static func fetchExamData() async throws -> SportExamInfo {
        let examURL = URL(string: "https://fdtyjw.fudan.edu.cn/sportScore/stScore.aspx?item=3")!
        let request = URLRequest(url: examURL)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let htmlText = String(data: data, encoding: String.Encoding.utf8) else {
            throw NetworkError.invalidResponse
        }
        let doc = try SwiftSoup.parse(htmlText)
        
        var info = SportExamInfo()
        info.parseInfo(doc)
        info.parseItems(doc)
        info.parseLogs(doc)
        return info
    }
}

// MARK: - Model

struct ExerciseInfo {
    var exerciseItems: [ExerciseItem] = []
    var exerciseLogs: [ExerciseLog] = []

    
    struct ExerciseItem: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }

    struct ExerciseLog: Identifiable {
        let id = UUID()
        let name: String
        let date: String
        let status: String
    }
    
    mutating func parseExerciseItems(_ doc: Document) {
        guard let statElement = try? doc.select("#pitem > table > tbody > tr:nth-of-type(4) > td > table > tbody").first() else {
            return
        }
        
        for row in statElement.children() {
            let count = row.childNodeSize()
            for i in stride(from: 0, to: count, by: 2) {
                do {
                    var exerciseName = try row.child(i).html()
                    exerciseName.removeLast(1) // remove "："
                    guard let exerciseCount = Int(try row.child(i + 1).html()) else {
                        continue
                    }
                    exerciseItems.append(ExerciseItem(name: exerciseName, count: exerciseCount))
                } catch {
                    continue
                }
            }
        }
    }
    
    mutating func parseExerciseLogs(_ doc: Document) {
        guard let logElement = try? doc.select("#pitem > table > tbody > tr:nth-of-type(7) > td > table > tbody").first() else {
            return
        }
        
        for row in logElement.children() {
            do {
                let name = try row.child(1).html()
                let date = try row.child(2).html()
                var time = try row.child(3).html()
                let status = try row.child(4).html()
                
                // filter "--" from time string
                let pattern =  #/
                    (?<time> \d+:\d+)
                    *
                /#
                if let timeStr = time.firstMatch(of: pattern)?.time {
                    time = String(timeStr)
                }
                
                exerciseLogs.append(ExerciseLog(name: name, date: "\(date) \(time)", status: status))
            } catch {
                continue
            }
        }
    }
}

struct SportExamInfo {
    var items: [TestItem] = []
    var logs: [TestLog] = []
    var total: Double = 0.0
    var evaluation: String = ""
    
    struct TestItem: Identifiable {
        let id = UUID()
        let name: String
        let result: String
        let score: Int
        let status: String
    }
    
    struct TestLog: Identifiable {
        let id = UUID()
        let name: String
        let date: String
        let result: String
    }
    
    mutating func parseInfo(_ doc: Document) {
        guard let totalText = try? doc.select("#pitem > table > tbody > tr:nth-child(4) > td > table > tbody > tr:nth-child(11) > td:nth-child(3) > red").first()?.html() else {
            return
        }
        guard let total = Double(totalText) else {
            return
        }
        self.total = total
        
        guard let evaluation = try? doc.select("#pitem > table > tbody > tr:nth-child(4) > td > table > tbody > tr:nth-child(11) > td:nth-child(5) > red").first()?.html() else {
            return
        }
        self.evaluation = evaluation
    }
    
    mutating func parseItems(_ doc: Document) {
        guard let itemsTable = try? doc.select("#pitem > table > tbody > tr:nth-child(4) > td > table > tbody").first() else {
            return
        }
        
        for i in 0...5 {
            do {
                let row = itemsTable.child(i)
                let name = try row.child(1).html()
                let result = try row.child(2).html()
                let scoreText = try row.child(3).html()
                    .components(separatedBy: CharacterSet.decimalDigits.inverted).joined()  // filter non-digits
                guard let score = Int(scoreText) else { continue }
                let status = try row.child(4).html().replacingOccurrences(of: " &nbsp;", with: "")
                items.append(TestItem(name: name,
                                      result: result,
                                      score: Int(score),
                                      status: status))
            } catch {
                continue
            }
        }
    }
    
    mutating func parseLogs(_ doc: Document) {
        guard let itemsTable = try? doc.select("#pitem > table > tbody > tr:nth-child(11) > td > table > tbody").first() else {
            return
        }
        
        do {
            for row in itemsTable.children() {
                let name = try row.child(1).html()
                let date = try row.child(3).html()
                let result = try row.child(4).html()
                logs.append(TestLog(name: name, date: date, result: result))
            }
        } catch {
            return
        }
    }
}
