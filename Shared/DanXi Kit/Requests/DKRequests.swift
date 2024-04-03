import Foundation
import SwiftUI

struct DKRequests {
    
    // MARK: Course Info
    
    
    /// Get all course groups.
    static func loadCourseGroups() async throws -> [DKCourseGroup] {
        @ObservedObject var urls = FDUHoleUrls.shared
        return try await DXResponse(URL(string: urls.dankeBaseUrl + "/courses")!)
    }
    
    
    /// Get course group by ID.
    static func loadCourseGroup(id: Int) async throws -> DKCourseGroup {
        @ObservedObject var urls = FDUHoleUrls.shared
        let components = URLComponents(string: urls.dankeBaseUrl + "/group/\(id)")!
        return try await DXResponse(components.url!)
    }
    
    
    /// Get course groups hash.
    static func loadCourseHash() async throws -> String {
        struct Hash: Codable {
            let hash: String
        }
        
        @ObservedObject var urls = FDUHoleUrls.shared
        
        let hash: Hash = try await DXResponse(URL(string: urls.dankeBaseUrl + "/courses/hash")!)
        return hash.hash
    }
    

    /// Get course by ID.
    static func loadCourse(id: Int) async throws -> DKCourse {
        @ObservedObject var urls = FDUHoleUrls.shared
        
        return try await DXResponse(URL(string: urls.dankeBaseUrl + "/course/\(id)")!)
    }
    
    
    // MARK: Review
    
    
    /// Get all reviews published by me.
    static func myReviews() async throws -> [DKReview] {
        @ObservedObject var urls = FDUHoleUrls.shared
        
        return try await DXResponse(URL(string: urls.dankeBaseUrl + "/reviews/me")!)
    }
    
    
    
    /// Get all reviews on course with the given course ID.
    /// - Parameter courseId: Course ID.
    /// - Returns: Review list.
    static func loadReviews(courseId: Int) async throws -> [DKReview] {
        @ObservedObject var urls = FDUHoleUrls.shared
        
        return try await DXResponse(URL(string: urls.dankeBaseUrl + "/courses/\(courseId)/reviews")!)
    }
    
    
    
    /// Add or modify a review
    /// - Parameters:
    ///   - courseId: Course ID.
    ///   - content: Review content.
    ///   - title: Review title.
    ///   - rank: Rank struct, as in `DKRank`.
    ///   - modify: Whether to post new or modify existing review.
    /// - Returns: Review struct.
    static func postReview(courseId: Int, content: String, title: String, rank: DKRank, modify: Bool = false) async throws -> DKReview {
        struct ReviewConfig: Codable {
            let title, content: String
            let rank: DKRank
        }
        
        @ObservedObject var urls = FDUHoleUrls.shared

        return try await DXResponse(URL(string: urls.dankeBaseUrl + "/courses/\(courseId)/reviews")!,
                                    payload: ReviewConfig(title: title, content: content, rank: rank),
                                    method: modify ? "PUT" : "POST")
    }
    
    
    /// Remove review by ID.
    /// - Parameter id: Review ID.
    static func removeReview(id: Int) async throws {
        @ObservedObject var urls = FDUHoleUrls.shared
        
        try await DXRequest(URL(string: urls.dankeBaseUrl + "reviews/\(id)")!, method: "DELETE")
    }
    
    
    
    /// Vote for a review.
    /// - Parameters:
    ///   - reviewId: Review ID.
    ///   - upvote: Upvote or downvote.
    /// - Returns: New review struct.
    static func voteReview(reviewId: Int, upvote: Bool) async throws -> DKReview {
        struct UpvoteConfig: Codable {
            let upvote: Bool
        }
        
        @ObservedObject var urls = FDUHoleUrls.shared

        return try await DXResponse(URL(string: urls.dankeBaseUrl + "/reviews/\(reviewId)")!,
                                    payload: UpvoteConfig(upvote: upvote), method: "PATCH")
    }
}
