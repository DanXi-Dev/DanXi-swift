import Foundation

/// App-wide cache for wallet-related functions. Cache is invalidated between app launches.
public actor WalletStore {
    public static let shared = WalletStore()
    
    var userInfo: UserInfo? = nil
    var dailyTransactionHistory: [DateBoundValueData]? = nil
    var page = 1
    var finished = false
    var transactions: [Transaction] = []
    
    public func getCachedDailyTransactionHistory() async throws -> [DateBoundValueData] {
        if let dailyTransactionHistory = dailyTransactionHistory {
            return dailyTransactionHistory
        }
        
        return try await getRefreshedDailyTransactionHistory()
    }
    
    public func getRefreshedDailyTransactionHistory() async throws -> [DateBoundValueData] {
        let dailyTransactionHistory = try await WalletAPI.getTransactionHistoryByDay()
        self.dailyTransactionHistory = dailyTransactionHistory
        return dailyTransactionHistory
    }
    
    public func getCachedUserInfo() async throws -> UserInfo {
        if let userInfo = userInfo {
            return userInfo
        }
        
        return try await getRefreshedBalance()
    }
    
    public func getRefreshedBalance() async throws -> UserInfo {
        let userInfo = try await WalletAPI.getUserInfo()
        self.userInfo = userInfo
        return userInfo
    }
    
    public func getCachedTransactions() async throws -> [Transaction] {
        if finished {
            return self.transactions
        }
        
        let transactions = try await WalletAPI.getTransactions(page: page)
        page += 1
        finished = transactions.isEmpty
        self.transactions += transactions
        return self.transactions
    }
    
    public func getRefreshedTransactions() async throws -> [Transaction] {
        page = 1
        finished = false
        self.transactions = []
        
        let transactions = try await WalletAPI.getTransactions(page: page)
        page += 1
        finished = transactions.isEmpty
        self.transactions += transactions
        return self.transactions
    }
}
