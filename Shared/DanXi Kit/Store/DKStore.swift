import Foundation

class DKStore: ObservableObject {
    static var shared = DKStore()
    
    @Published var courses: [DKCourseGroup] = []
    @Published var initialized = false
    
    private let defaults = UserDefaults.standard
    
    private func loadCourseCache() throws {
        let courses: [DKCourseGroup] = try FileStore.caches.loadDecoded("dk-course-list.data")
        Task { @MainActor in
            self.courses = courses
        }
    }
    
    private func updateCourseCache(_ newHash: String) async throws {
        let courses = try await DKRequests.loadCourseGroups()
        try FileStore.caches.saveEncoded(self.courses, filename: "dk-course-list.data")
        defaults.setValue(newHash, forKey: "dk-course-hash")
        
        Task { @MainActor in
            self.courses = courses
        }
    }
    
    func loadCourses() async throws {
        guard !initialized else { return }
        
        let newHash = try await DKRequests.loadCourseHash()
        
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
            try FileStore.caches.remove("dk-course-list.data")
        } catch { }
    }
}
