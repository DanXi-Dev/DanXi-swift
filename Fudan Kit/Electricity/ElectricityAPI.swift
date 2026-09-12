import Foundation

/// API for dormitory electricity usage
public enum ElectricityAPI {
    /// Get electricity usage
    ///
    /// Note: some student might not be able to use this API, and the API will
    /// return an error. This will be handled by `unwrapJSON` and throw a
    /// `.customError` with error message.
    public static func getElectricityUsage() async throws -> ElectricityUsage {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanelec/wap/default/info")!
        let data = try await Authenticator.shared.authenticate(url)
        let unwrapped = try unwrapJSON(data).rawData()
        return try JSONDecoder().decode(ElectricityUsage.self, from: unwrapped)
    }
}
