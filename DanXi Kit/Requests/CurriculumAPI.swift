import Foundation
import SwiftyJSON

public enum CurriculumAPI {
    
    // MARK: - Course
    
    public static func listCourseGroups() async throws -> [CourseGroup] {
        return try await requestWithResponse("/courses", base: curriculumURL)
    }
    
    public static func getCourseGroup(id: Int) async throws -> CourseGroup {
        return try await requestWithResponse("/group/\(id)", base: curriculumURL)
    }
    
    public static func getCourseGroupsHash() async throws -> String {
        let data = try await requestWithData("/courses/hash", base: curriculumURL)
        let json = try JSON(data: data)
        guard let hash = json["hash"].string else {
            throw URLError(.badServerResponse)
        }
        return hash
    }
    
    public static func getCourse(id: Int) async throws -> Course {
        return try await requestWithResponse("/course/\(id)", base: curriculumURL)
    }
    
    // MARK: - Review
    
    public static func listMyReviews() async throws -> [Review] {
        return try await requestWithResponse("/reviews/me", base: curriculumURL)
    }
    
    public static func listReviews(courseId: Int) async throws -> [Review] {
        return try await requestWithResponse("/courses/\(courseId)/reviews", base: curriculumURL)
    }
    
    public static func createReview(courseId: Int, title: String, content: String, rank: Rank) async throws -> Review {
        let rankMap = ["overall": rank.overall, "content": rank.content, "workload": rank.workload, "assessment": rank.assessment]
        let payload: [String: Any] = ["title": title, "content": content, "rank": rankMap]
        return try await requestWithResponse("/courses/\(courseId)/reviews", base: curriculumURL, payload: payload, method: "POST")
    }
    
    public static func modifyReview(courseId: Int, title: String, content: String, rank: Rank) async throws -> Review {
        let rankMap = ["overall": rank.overall, "content": rank.content, "workload": rank.workload, "assessment": rank.assessment]
        let payload: [String: Any] = ["title": title, "content": content, "rank": rankMap]
        return try await requestWithResponse("/courses/\(courseId)/reviews", base: curriculumURL, payload: payload, method: "PUT")
    }
    
    public static func deleteReview(id: Int) async throws {
        try await requestWithoutResponse("/reviews/\(id)", base: curriculumURL, method: "DELETE")
    }
    
    public static func voteReview(id: Int, upvote: Bool) async throws -> Review {
        let payload = ["upvote": upvote]
        return try await requestWithResponse("/reviews/\(id)", base: curriculumURL, payload: payload, method: "PATCH")
    }
    
    // MARK: - Sensitive
    
    public static func listAllSensitiveReviews() async throws -> [CurriculumSensitive] {
        let params = ["all": "true"]
        return try await requestWithResponse("/v3/reviews/_sensitive", base: curriculumURL, params: params)
    }
    
    public static func setReviewSensitive(reviewId: Int, sensitive: Bool) async throws {
        let payload = ["is_actually_sensitive": sensitive]
        try await requestWithoutResponse("/v3/reviews/\(reviewId)/_sensitive", base: curriculumURL, payload: payload, method: "PUT")
    }
}
