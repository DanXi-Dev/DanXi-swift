import Foundation

/// API for dormitory electricity usage
internal enum ElectricityAPI {
    
    /// Get electricity usage
    ///
    /// Note: some student might not be able to use this API, and the API will
    /// return an error. This will be handled by `unwrapJSON` and throw a
    /// `.customError` with error message.
    public static func getElectricityUsage() async throws -> ElectricityUsage {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanelec/wap/default/info")!
        let data = try await AuthenticationAPI.authenticateForData(url)
        let unwrapped = try unwrapJSON(data).rawData()
        return try JSONDecoder().decode(ElectricityUsage.self, from: unwrapped)
    }
    
    public static func getElectricityUsageHistoryByDay() async throws -> [DateBoundValueData] {
        let url = URL(string: "https://my.fudan.edu.cn/data_tables/ykt_xszsqyydqk.json")!
        let _ = try await AuthenticationAPI.authenticateForData(url)
        let payload = "draw=1&columns%5B0%5D%5Bdata%5D=0&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=1&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=10&search%5Bvalue%5D=&search%5Bregex%5D=false"
        let request = constructRequest(url, payload: payload.data(using: .utf8))
        let (data, _) = try await URLSession.campusSession.data(for: request)
        return try JSONDecoder().decode(FDMyAPIJsonResponse.self, from: data).dateValuePairs
    }
}
