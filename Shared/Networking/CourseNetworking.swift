import Foundation

// curriculum board networks

let DANKE_BASE_URL = "https://danke.fduhole.com/api"

extension NetworkRequests {
    
    // MARK: course info
    
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
    
    // MARK: review
    
    func review(courseId: Int, content: String, title: String, rank: DKRank, modify: Bool = false) async throws -> DKReview {
        struct ReviewObj: Codable {
            let title, content: String
            let rank: DKRank
        }
        
        let payload = ReviewObj(title: title, content: content, rank: rank)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: DANKE_BASE_URL + "/course/\(courseId)/reviews")!
        return try await requestObj(url: components.url!, data: payloadData, method: modify ? "PUT" : "POST")
    }
    
    func myReviews() async throws -> [DKReview] {
        let components = URLComponents(string: DANKE_BASE_URL + "/reviews/me")!
        return try await requestObj(url: components.url!)
    }
    
    func upvote(reviewId: Int, upvote: Bool) async throws -> DKReview {
        struct UpvoteConfig: Codable {
            let upvote: Bool
        }
        
        let payload = UpvoteConfig(upvote: upvote)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: DANKE_BASE_URL + "/reviews/\(reviewId)")!
        return try await requestObj(url: components.url!, data: payloadData, method: "PATCH")
    }
}
