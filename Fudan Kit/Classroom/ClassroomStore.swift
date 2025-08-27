import Foundation

public actor ClassroomStore {
    public static let shared = ClassroomStore()
    
    var classroomsCache: [Building: [Classroom]] = [:]
    
    private var lastLoginDate: Date? = nil
    
    private var shouldLogin: Bool {
        guard let lastLoginDate else { return true }
        
        var dateComponents = DateComponents()
        dateComponents.hour = 2
        
        let calendar = Calendar.current
        guard let addedDate = calendar.date(byAdding: dateComponents, to: lastLoginDate) else { return true }
        
        return addedDate < Date.now
    }
    
    private func authenticate() async throws {
        if shouldLogin {
            _ = try await Authenticator.neo.authenticate(URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!)
            lastLoginDate = Date()
        }
    }
    
    public func getCachedClassroom(building: Building) async throws -> [Classroom] {
        if let classrooms = classroomsCache[building] {
            return classrooms
        }
        
        try await authenticate()
        let classrooms = try await ClassroomAPI.getClassrooms(building: building)
        classroomsCache[building] = classrooms
        return classrooms
    }
    
    public func getRefreshedClassroom(building: Building) async throws -> [Classroom] {
        try await authenticate()
        let classrooms = try await ClassroomAPI.getClassrooms(building: building)
        classroomsCache[building] = classrooms
        return classrooms
    }
    
    public func setupPreview(_ cache: [Building: [Classroom]]) {
        self.classroomsCache = cache
    }
}
