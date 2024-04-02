import Foundation

/// App-wide cache for wallet-related functions. Cache is invalidated between app launches.
public actor WalletStore {
    public static let shared = WalletStore()
    
    var balance: String? = nil
    var page = 1
    var finished = false
    var transactions: [Transaction] = []
    
    /// Warning: This API is slow, use MyAPI instead
    public func getCachedBalance() async throws -> String {
        if let balance = balance {
            return balance
        }
        
        let balance = try await WalletAPI.getBalance()
        self.balance = balance
        return balance
    }
    
    /// Warning: This API is slow, use MyAPI instead
    public func getRefreshedBalance() async throws -> String {
        let balance = try await WalletAPI.getBalance()
        self.balance = balance
        return balance
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
