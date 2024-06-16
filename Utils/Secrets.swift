import Foundation

/// Struct for decoding secret URLs from `secrets.json`.
///
/// These fields are decoded from `secrets.json`, which is injected by CI using the following environment values:
/// - `AUTH_URL`
/// - `FORUM_URL`
/// - `CURRICULUM_URL`
struct SecretURLs: Codable {
    let authURL: String
    let forumURL: String
    let curriculumURL: String
}

public enum Secrets {
    /// Decode secret test URLs from `secrets.json`, which is modified with CI environments
    /// - Returns: Tuple of 3 URLs for testing purposes, which are for auth, forum and curriculum. `nil` if failed to decode.
    public static func getSecretURLs() -> (URL, URL, URL)? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let path = Bundle.module.url(forResource: "secrets", withExtension: "json"),
              let data = try? Data(contentsOf: path),
              let secret = try? decoder.decode(SecretURLs.self, from: data) else {
            return nil
        }
        
        guard let authURL = URL(string: secret.authURL),
              let forumURL = URL(string: secret.forumURL),
              let curriculumURL = URL(string: secret.curriculumURL) else {
            return nil
        }
        
        return (authURL, forumURL, curriculumURL)
    }
}
