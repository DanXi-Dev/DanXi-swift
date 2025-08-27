import Foundation

/// API for getting student profile
public enum ProfileAPI {
    public static func getStudentProfile() async throws -> Profile {
        let url = URL(string: "https://workflow1.fudan.edu.cn/site/fudan/student-information")!
        let data = try await Authenticator.classic.authenticate(url)
        let json = try unwrapJSON(data)
        let content = try json["info"].rawData()
        let response = try JSONDecoder().decode(ProfileResponse.self, from: content)
        return Profile(campusId: response.XH, name: response.XM, gender: response.XB, idNumber: response.ZJHM, department: response.YX, major: response.ZY)
    }
    
    private struct ProfileResponse: Decodable {
        let XH: String
        let XM: String
        let XB: String
        let ZJHM: String
        let YX: String
        let ZY: String
    }
}
