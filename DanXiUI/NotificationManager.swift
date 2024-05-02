import SwiftUI
import DanXiKit

public class NotificationManager {
    public static let shared = NotificationManager()
    
    var cachedDeviceId: String? = nil
    var cachedAPNSToken: String? = nil
    
    public func receiveToken(_ tokenData: Data, _ deviceId: UUID) {
        setCache(tokenData: tokenData, deviceId: deviceId)
        if CommunityModel.shared.loggedIn {
            uploadAPNSToken()
        }
    }
    
    func setCache(tokenData: Data, deviceId: UUID) {
        cachedAPNSToken = tokenData.map { String(format: "%.2hhx", $0) }.joined()
        cachedDeviceId = deviceId.uuidString
    }
    
    func uploadAPNSToken() {
        guard let deviceId = cachedDeviceId, let token = cachedAPNSToken else {
            return
        }
        Task(priority: .background) {
            try await ForumAPI.uploadNotificationToken(deviceId: deviceId, token: token)
        }
    }
    
    func uploadAPNSToken(token: String, deviceId: String) {
        Task(priority: .background) {
            try await ForumAPI.uploadNotificationToken(deviceId: deviceId, token: token)
        }
    }
}
