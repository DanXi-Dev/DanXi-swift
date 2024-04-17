import Foundation
import SwiftyJSON

public enum CurriculumnAPI {
    
    // MARK: - Course
    
    public static func listCourseGroups() async throws -> [CourseGroup] {
        return try await requestWithResponse("/courses", base: curriculumnURL)
    }
    
    public static func getCourseGroup(id: Int) async throws -> CourseGroup {
        return try await requestWithResponse("/group/\(id)", base: curriculumnURL)
    }
    
    public static func getCourseGroupsHash() async throws -> String {
        let data = try await requestWithData("/courses/hash", base: curriculumnURL)
        let json = try JSON(data: data)
        guard let hash = json["hash"].string else {
            throw URLError(.badServerResponse)
        }
        return hash
    }
    
    public static func getCourse(id: Int) async throws -> Course {
        return try await requestWithResponse("/course/\(id)", base: curriculumnURL)
    }
    
    // MARK: - Review
    
    public static func listMyReviews() async throws -> [Review] {
        return try await requestWithResponse("/reviews/me", base: curriculumnURL)
    }
    
    public static func listReviews(courseId: Int) async throws -> [Review] {
        return try await requestWithResponse("/courses/\(courseId)/reviews", base: curriculumnURL)
    }
    
    public static func createReview(courseId: Int, title: String, content: String, rank: Rank) async throws -> Review {
        let payload: [String: Any] = ["title": title, "content": content, "rank": rank]
        return try await requestWithResponse("/courses/\(courseId)/reviews", base: curriculumnURL, payload: payload, method: "POST")
    }
    
    public static func modifyReview(courseId: Int, title: String, content: String, rank: Rank) async throws -> Review {
        let payload: [String: Any] = ["title": title, "content": content, "rank": rank]
        return try await requestWithResponse("/courses/\(courseId)/reviews", base: curriculumnURL, payload: payload, method: "PUT")
    }
    
    public static func deleteReview(id: Int) async throws {
        try await requestWithoutResponse("/reviews/\(id)", base: curriculumnURL, method: "DELETE")
    }
    
    public static func voteReview(id: Int, upvote: Bool) async throws -> Review {
        let payload = ["upvote": upvote]
        return try await requestWithResponse("/reviews/\(id)", base: curriculumnURL, payload: payload, method: "PATCH")
    }
}
