import Foundation

public actor ClassroomStore {
    public static let shared = ClassroomStore()
    
    var classroomsCache: [Building: [Classroom]] = [:]
    
    public func getCachedClassroom(building: Building) async throws -> [Classroom] {
        if let classrooms = classroomsCache[building] {
            return classrooms
        }
        
        let classrooms = try await ClassroomAPI.getClassrooms(building: building)
        classroomsCache[building] = classrooms
        return classrooms
    }
    
    public func getRefreshedClassroom(building: Building) async throws -> [Classroom] {
        let classrooms = try await ClassroomAPI.getClassrooms(building: building)
        classroomsCache[building] = classrooms
        return classrooms
    }
}
