import Foundation

func cacheFileURL() throws -> URL {
    try FileManager.default.url(for: .cachesDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: false)
    .appendingPathComponent("dk-course-list.data")
}

func loadDKCourseList() -> [DKCourseGroup] {
    do {
        let fileURL = try cacheFileURL()
        guard let file = try? FileHandle(forReadingFrom: fileURL) else {
            return []
        }
        return try JSONDecoder().decode([DKCourseGroup].self, from: file.availableData)
    } catch {
        return []
    }
}

func saveDKCourseList(_ list: [DKCourseGroup]) {
    do {
        let data = try JSONEncoder().encode(list)
        let outfile = try cacheFileURL()
        try data.write(to: outfile)
    } catch {
        print("DANXI-DEBUG: save course list failed")
    }
}
