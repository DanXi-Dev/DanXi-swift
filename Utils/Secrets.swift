import Foundation

/// Struct for decoding secret URLs from `secrets.json`.
///
/// These fields are decoded from `secrets.json`, which is injected by CI using the following environment values:
/// - `AUTH_TEST_URL`
/// - `FORUM_TEST_URL`
/// - `CURRICULUM_TEST_URL`
struct SecretURLs: Codable {
    let authTestURL: String
    let forumTestURL: String
    let curriculumTestURL: String
}

public enum Secrets {
    /// Decode secret test URLs from `secrets.json`, which is modified with CI environments
    /// - Returns: Tuple of 3 URLs for testing purposes, which are for auth, forum and curriculum. `nil` if failed to decode.
    public static func getSecretURLs() -> (URL, URL, URL)? {
        let decoder = JSONDecoder()
        
        guard let path = Bundle.module.url(forResource: "secrets", withExtension: "json"),
              let data = try? Data(contentsOf: path),
              let secret = try? decoder.decode(SecretURLs.self, from: data) else {
            return nil
        }
        
        guard let authURL = URL(string: secret.authTestURL),
              let forumURL = URL(string: secret.forumTestURL),
              let curriculumURL = URL(string: secret.curriculumTestURL) else {
            return nil
        }
        
        return (authURL, forumURL, curriculumURL)
    }
}
