import Foundation

public struct Questions: Decodable {
    public let version: Int
    public let questions: [Question]
}

public struct Question: Identifiable, Decodable {
    public let id: Int
    public let type: QuestionType
    public let group: QuestionGroup
    public let question: String
    public let option: [String]
}

public enum QuestionType: String, Decodable {
    case trueOrFalse = "true-or-false"
    case singleSelection = "single-selection"
    case multipleSelection = "multi-selection"
}

public enum QuestionGroup: String, Decodable {
    case required
    case optional
}

public enum QuestionResponse {
    case success(Token)
    case fail([Int])
}
