import Foundation

public actor MyStore {
    public static let shared = MyStore()
    
    let dataValidFor: TimeInterval = 1 * 60 * 60
    public var lastUpdated = Date.distantPast
    public var outdated: Bool {
        lastUpdated + dataValidFor < Date.now
    }
    
    public func clearCache() {
        electricityLog = nil
        userInfo = nil
        walletLogs = nil
    }
    
    var electricityLog: [ElectricityLog]? = nil
    
    public func getCachedElectricityLogs() async throws -> [ElectricityLog] {
        if let electricityLog = electricityLog {
            return electricityLog
        }
        
        return try await getRefreshedElectricityLogs()
    }
    
    public func getRefreshedElectricityLogs() async throws -> [ElectricityLog] {
        let electricityLog = try await MyAPI.getElectricityLogs()
        self.electricityLog = electricityLog
        self.lastUpdated = Date.now
        return electricityLog
    }
    
    var userInfo: UserInfo? = nil
    
    public func getCachedUserInfo() async throws -> UserInfo {
        if let userInfo = userInfo {
            return userInfo
        }
        return try await getRefreshedUserInfo()
    }
    
    public func getRefreshedUserInfo() async throws -> UserInfo {
        let userInfo = try await MyAPI.getUserInfo()
        self.userInfo = userInfo
        return userInfo
    }
    
    var walletLogs: [WalletLog]? = nil
    
    public func getCachedWalletLogs() async throws -> [WalletLog] {
        if let walletLogs = walletLogs {
            return walletLogs
        }
        return try await getRefreshedWalletLogs()
    }
    
    public func getRefreshedWalletLogs() async throws -> [WalletLog] {
        let walletLogs = try await MyAPI.getWalletLogs()
        self.walletLogs = walletLogs
        self.lastUpdated = Date.now
        return walletLogs
    }
    
    public func setupPreivew(electricity: [ElectricityLog], wallet: [WalletLog], user: UserInfo? = nil) {
        electricityLog = electricity
        userInfo = user
        walletLogs = wallet
    }
}
