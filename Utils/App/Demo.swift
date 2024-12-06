import Foundation

/// Struct for decoding demo URLs from `demo.json`.
///
/// These fields are decoded from `demo.json`, which is injected by CI using the following environment values:
/// - `AUTH_TEST_URL`
/// - `FORUM_TEST_URL`
/// - `CURRICULUM_TEST_URL`
struct demoURLs: Codable {
    let authTestURL: String
    let forumTestURL: String
    let curriculumTestURL: String
}

public enum Demo {
    /// Decode demo test URLs from `demo.json`, which is modified with CI environments
    /// - Returns: Tuple of 3 URLs for testing purposes, which are for auth, forum and curriculum. `nil` if failed to decode.
    public static func getDemoURLs() -> (URL, URL, URL)? {
        let decoder = JSONDecoder()
        
        guard let path = Bundle.module.url(forResource: "demo", withExtension: "json"),
              let data = try? Data(contentsOf: path),
              let demo = try? decoder.decode(demoURLs.self, from: data) else {
            return nil
        }
        
        guard let authURL = URL(string: demo.authTestURL),
              let forumURL = URL(string: demo.forumTestURL),
              let curriculumURL = URL(string: demo.curriculumTestURL) else {
            return nil
        }
        
        return (authURL, forumURL, curriculumURL)
    }
}
