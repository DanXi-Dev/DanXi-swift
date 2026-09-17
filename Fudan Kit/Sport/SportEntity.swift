import Foundation

/// The count of a certain type of exercise
public struct Exercise: Identifiable, Codable {
    public let id: UUID
    public let category: String
    public let count: Int
}

/// The log of an exercise event
public struct ExerciseLog: Identifiable, Codable {
    public let id: UUID
    public let category: String
    public let date: String
    public let status: String
}

public struct SportExam: Codable {
    public let total: Double
    public let evaluation: String
    public let items: [SportExamItem]
    public let logs: [SportExamLog]
}

/// The result of a sport exam
public struct SportExamItem: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let result: String
    public let score: Int
    public let status: String
}

/// The log of a sport exam
public struct SportExamLog: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let date: String
    public let result: String
}
