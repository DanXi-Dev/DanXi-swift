import Foundation

/// App-wide cache for sport-related data, including exercises and sport exams.
public actor SportStore {
    public static let shared = SportStore()

    var exercises: [Exercise]? = nil
    var exerciseLogs: [ExerciseLog]? = nil
    
    public func getCachedExercises() async throws -> ([Exercise], [ExerciseLog]) {
        if let exercises = exercises,
           let logs = exerciseLogs {
            return (exercises, logs)
        }
        
        return try await getRefreshedExercises()
    }
    
    public func getRefreshedExercises() async throws -> ([Exercise], [ExerciseLog]) {
        let (exercise, logs) = try await SportAPI.getExercise()
        self.exercises = exercise
        self.exerciseLogs = logs
        return (exercise, logs)
    }
    
    var exam: SportExam? = nil
    
    public func getCachedExam() async throws -> SportExam {
        if let exam = exam {
            return exam
        }
        return try await getRefreshedExam()
    }
    
    public func getRefreshedExam() async throws -> SportExam {
        let exam = try await SportAPI.getExam()
        self.exam = exam
        return exam
    }
    
    public func setupPreview(exercises: [Exercise], exerciseLogs: [ExerciseLog]) {
        self.exercises = exercises
        self.exerciseLogs = exerciseLogs
    }
}
