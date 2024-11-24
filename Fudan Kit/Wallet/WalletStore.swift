import Foundation

/// App-wide cache for wallet-related functions. Cache is invalidated between app launches.
public actor WalletStore {
    public static let shared = WalletStore()
    
    var balance: String? = nil
    var page = 1
    var finished = false
    var transactions: [Transaction] = []
    let dataValidFor: TimeInterval = 1 * 60 * 60
    public var lastUpdated = Date.distantPast
    public var outdated: Bool {
        lastUpdated + dataValidFor < Date.now
    }
    
    public func clearCache() {
        balance = nil
        transactions = []
        page = 1
        finished = false
    }
    
    /// Warning: This API is slow, use MyAPI instead
    public func getCachedBalance() async throws -> String {
        if let balance = balance {
            return balance
        }
        
        return try await getRefreshedBalance()
    }
    
    /// Warning: This API is slow, use MyAPI instead
    public func getRefreshedBalance() async throws -> String {
        let balance = try await WalletAPI.getBalance()
        self.balance = balance
        self.lastUpdated = Date.now
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
        self.lastUpdated = Date.now
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
        self.lastUpdated = Date.now
        return self.transactions
    }
    
    public func setupPreview(transactions: [Transaction]) {
        finished = true
        self.transactions = transactions
    }
}
