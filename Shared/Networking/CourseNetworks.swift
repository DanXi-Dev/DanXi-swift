import Foundation

let DANKE_BASE_URL = "https://danke.fduhole.com/api"

extension DXNetworks {
    
    // MARK: Course Info
    
    func loadCourseGroups() async throws -> [DKCourseGroup] {
        return try await requestObj(url: URL(string: DANKE_BASE_URL + "/courses")!)
    }
    
    func loadCourseHash() async throws -> String {
        struct Hash: Codable {
            let hash: String
        }
        
        let hash: Hash = try await requestObj(url: URL(string: DANKE_BASE_URL + "/courses/hash")!)
        return hash.hash
    }
    
    func loadCourseGroup(id: Int) async throws -> DKCourseGroup {
        let components = URLComponents(string: DANKE_BASE_URL + "/group/\(id)")!
        return try await requestObj(url: components.url!)
    }
    
    // MARK: Review
    
    func review(courseId: Int, content: String, title: String, rank: DKRank, modify: Bool = false) async throws -> DKReview {
        struct ReviewConfig: Codable {
            let title, content: String
            let rank: DKRank
        }

        return try await requestObj(url: URL(string: DANKE_BASE_URL + "/course/\(courseId)/reviews")!,
                                    payload: ReviewConfig(title: title, content: content, rank: rank),
                                    method: modify ? "PUT" : "POST")
    }
    
    func myReviews() async throws -> [DKReview] {
        return try await requestObj(url: URL(string: DANKE_BASE_URL + "/reviews/me")!)
    }
    
    func upvote(reviewId: Int, upvote: Bool) async throws -> DKReview {
        struct UpvoteConfig: Codable {
            let upvote: Bool
        }

        return try await requestObj(url: URL(string: DANKE_BASE_URL + "/reviews/\(reviewId)")!,
                                    payload: UpvoteConfig(upvote: upvote), method: "PATCH")
    }
}
