import Foundation

/// The count of a certain type of exercise
public struct Exercise: Identifiable {
    public let id: UUID
    public let category: String
    public let count: Int
}

/// The log of an exercise event
public struct ExerciseLog: Identifiable {
    public let id: UUID
    public let category: String
    public let date: String
    public let status: String
}

public struct SportExam {
    let total: Double
    let evaluation: String
    
    let items: [SportExamItem]
    let logs: [SportExamLog]
}

/// The result of a sport exam
public struct SportExamItem: Identifiable {
    public let id: UUID
    public let name: String
    public let result: String
    public let score: Int
    public let status: String
}

/// The log of a sport exam
public struct SportExamLog: Identifiable {
    public let id: UUID
    public let name: String
    public let date: String
    public let result: String
}
