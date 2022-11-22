import Foundation

class CourseStore: ObservableObject {
    static var shared = CourseStore()
    
    @Published var courses: [DKCourseGroup] = []
    @Published var initialized = false
    
    private let defaults = UserDefaults.standard
    
    private func loadCourseCache() throws {
        Task { @MainActor in
            self.courses = try loadData(filename: "dk-course-list.data")
        }
    }
    
    private func updateCourseCache(_ newHash: String) async throws {
        let courses = try await CourseRequest.loadCourseGroups()
        try saveData(self.courses, filename: "dk-course-list.data")
        defaults.setValue(newHash, forKey: "dk-course-hash")
        
        Task { @MainActor in
            self.courses = courses
        }
    }
    
    func loadCourses() async throws {
        guard !initialized else { return }
        
        let newHash = try await CourseRequest.loadCourseHash()
        
        if let oldHash = defaults.string(forKey: "dk-course-hash") {
            if oldHash == newHash {
                do {
                    try loadCourseCache()
                    Task { @MainActor in
                        self.initialized = true
                    }
                    return
                } catch { }
            }
        }
        
        try await updateCourseCache(newHash)
        
        Task { @MainActor in
            self.initialized = true
        }
    }
    
    func clear() {
        defaults.removeObject(forKey: "dk-course-hash")
        self.initialized = false
        do {
            try removeData(filename: "dk-course-list.data")
        } catch { }
    }
}
