import Foundation

// curriculum board networks

let DANKE_BASE_URL = "https://danke.fduhole.com/api"

extension NetworkRequests {
    func loadCourseGroups() async throws -> [DKCourseGroup] {
        let components = URLComponents(string: DANKE_BASE_URL + "/courses")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode([DKCourseGroup].self, from: data)
        return decodedResponse
    }
}
