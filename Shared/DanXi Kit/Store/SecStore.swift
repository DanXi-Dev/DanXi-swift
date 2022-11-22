import Foundation
import Security


struct SecStore {
    
    static var shared = SecStore()
    
    // MARK: Public Interfaces
    
    var token: Token?
    
    init() {
        do {
            token = try retrieveToken()
        } catch {
            token = nil
        }
    }
    
    mutating func store(_ token: Token) {
        do {
            self.token = token
            try storeToken(token)
        } catch {
            self.token = nil
        }
    }
    
    mutating func update(_ token: Token) {
        do {
            self.token = token
            try updateToken(token)
        } catch {
            self.token = nil
        }
    }
    
    mutating func delete() {
        self.token = nil
        deleteToken()
    }
    
    
    // MARK: KeyChain Operations
    
    private func storeToken(_ token: Token) throws {
        let keychainItem = [
            kSecValueData: try JSONEncoder().encode(token),
            kSecAttrServer: "fduhole.com",
            kSecClass: kSecClassInternetPassword
        ] as CFDictionary
        
        SecItemAdd(keychainItem, nil)
    }
    
    private func retrieveToken() throws -> Token? {
        var result: AnyObject?
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: "fduhole.com",
            kSecReturnAttributes: true,
            kSecReturnData: true
        ] as CFDictionary
        
        let status = SecItemCopyMatching(query, &result)
        guard status == 0 && result != nil else { // check if retrieving succeeded
            return nil
        }
        let dic = result as! NSDictionary
        let tokenData = dic[kSecValueData] as! Data
        return try JSONDecoder().decode(Token.self, from: tokenData)
    }
    
    private func updateToken(_ token: Token) throws {
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: "fduhole.com",
            kSecReturnAttributes: true,
            kSecReturnData: true
        ] as CFDictionary
        
        let updateFields = [
            kSecValueData: try JSONEncoder().encode(token)
        ] as CFDictionary
        
        SecItemUpdate(query, updateFields)
    }
    
    private func deleteToken() {
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: "fduhole.com"
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}

