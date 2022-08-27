import Foundation

// curriculum board networks

let DANKE_BASE_URL = "https://danke.fduhole.com/api"

extension NetworkRequests {
    func loadCourseGroups() async throws -> [DKCourseGroup] {
        let components = URLComponents(string: DANKE_BASE_URL + "/courses")!
        return try await requestObj(url: components.url!)
    }
    
    func loadCourseHash() async throws -> String {
        struct Hash: Codable {
            let hash: String
        }
        
        let components = URLComponents(string: DANKE_BASE_URL + "/courses/hash")!
        let data = try await networkRequest(url: components.url!)
        let hash = try JSONDecoder().decode(Hash.self, from: data)
        return hash.hash
    }
    
    func loadCourseGroup(id: Int) async throws -> DKCourseGroup {
        let components = URLComponents(string: DANKE_BASE_URL + "/group/\(id)")!
        return try await requestObj(url: components.url!)
    }
}
