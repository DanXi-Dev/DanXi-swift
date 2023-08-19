import Foundation

struct DXUser: Hashable, Codable, Identifiable {
    struct Config: Hashable, Codable {
        let notify: [String]
    }
    
    let id: Int
    let nickname: String
    let joinTime: Date
    let isAdmin: Bool
    var answered: Bool
    var banned: Dictionary<Int, Date>
    var config: Config
}


struct Token: Codable {
    let access: String
    let refresh: String
}

struct DXInfo: Codable {
    let id: String
    let content: String
    let type: Int
}

struct DXBanner: Codable {
    let title: String
    let actionName: String
    let action: String
}

struct Timetable: Codable {
    let semester: Int
    let startDate: Date
}

// MARK: Register Questions

struct DXQuestions: Decodable {
    let version: Int
    let questions: [DXQuestion]
}

struct DXQuestion: Identifiable, Decodable {
    enum QuestionType: String {
        case trueOrFalse = "true-or-false"
        case singleSelection = "single-selection"
        case multipleSelection = "multi-selection"
    }
    
    enum QuestionGroup: String {
        case required
        case optional
    }
    
    let id: Int
    let type: QuestionType
    let group: QuestionGroup
    let question: String
    let option: [String]
}
