import Foundation

/// App-wide cache for wallet-related functions. Cache is invalidated between app launches.
public actor WalletStore {
    public static let shared = WalletStore()
    
    var balance: String? = nil
    var page = 1
    var finished = false
    var transactions: [Transaction] = []
    
    func getCachedBalance() async throws -> String {
        if let balance = balance {
            return balance
        }
        
        let balance = try await WalletAPI.getBalance()
        self.balance = balance
        return balance
    }
    
    func getRefreshedBalance() async throws -> String {
        let balance = try await WalletAPI.getBalance()
        self.balance = balance
        return balance
    }
    
    func getCachedTransactions() async throws -> [Transaction] {
        if finished {
            return self.transactions
        }
        
        let transactions = try await WalletAPI.getTransactions(page: page)
        page += 1
        finished = transactions.isEmpty
        self.transactions += transactions
        return self.transactions
    }
    
    func getRefreshedTransactions() async throws -> [Transaction] {
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
