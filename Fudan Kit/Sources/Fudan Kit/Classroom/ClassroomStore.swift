import Foundation

public actor ClassroomStore {
    public static let shared = ClassroomStore()
    
    var vpnLogged = false
    var classroomsCache: [Building: [Classroom]] = [:]
    
    public func getCachedClassroom(building: Building) async throws -> [Classroom] {
        if let classrooms = classroomsCache[building] {
            return classrooms
        }
        
        if !vpnLogged {
            try await ClassroomAPI.loginVPN()
            vpnLogged = true
        }
        
        let classrooms = try await ClassroomAPI.getClassrooms(building: building)
        classroomsCache[building] = classrooms
        return classrooms
    }
    
    public func getRefreshedClassroom(building: Building) async throws -> [Classroom] {
        try await ClassroomAPI.loginVPN()
        vpnLogged = true
        let classrooms = try await ClassroomAPI.getClassrooms(building: building)
        classroomsCache[building] = classrooms
        return classrooms
    }
}
