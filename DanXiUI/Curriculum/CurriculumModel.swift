import SwiftUI
import Disk
import DanXiKit
import Utils

@MainActor
class CurriculumModel: ObservableObject {
    static var shared = CurriculumModel()
    
    @Published var courses: [CourseGroup] = []
    var hash: String?
    
    fileprivate struct CourseCache: Codable {
        let courses: [CourseGroup]
        let hash: String
    }
    
    func loadLocal() async throws {
        guard self.courses.isEmpty else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let cached = try? Disk.retrieve("fduhole/courses.json", from: .appGroup, as: CourseCache.self) {
            self.courses = cached.courses
            self.hash = cached.hash
            
            Task(priority: .background) {
                try? await loadRemote()
            }
        } else {
            try await loadRemote()
        }
    }
    
    func loadRemote() async throws {
        let remoteHash = try await CurriculumAPI.getCourseGroupsHash()
        if let localHash = self.hash {
            if localHash == remoteHash {
                return
            }
        }
        
        let courses = try await CurriculumAPI.listCourseGroups()
        self.courses = courses
        Task {
            let cache = CourseCache(courses: courses, hash: remoteHash)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try Disk.save(cache, to: .appGroup, as: "fduhole/courses.json", encoder: encoder)
        }
    }
    
    func clearAll() {
        self.courses = []
        Task {
            try Disk.remove("fduhole/courses.json", from: .appGroup)
        }
    }
}
