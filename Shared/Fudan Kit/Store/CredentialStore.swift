import Foundation
import Security

struct CredentialStore {
    static var shared = CredentialStore()
    
    var username: String?
    var password: String?
    
    init() {
        (self.username, self.password) = retrieveCredential()
    }
    
    mutating func store(_ username: String, _ password: String) {
        self.username = username
        self.password = password
        storeCredential(username, password)
    }
    
    mutating func delete() {
        self.username = nil
        self.password = nil
        
        deleteCredential()
    }
    
    private func storeCredential(_ username: String, _ password: String) {
        let keychainItem = [
            kSecValueData: password.data(using: .utf8)!,
            kSecAttrServer: "fudan.edu.cn",
            kSecAttrAccount: username,
            kSecClass: kSecClassInternetPassword
        ] as CFDictionary
        
        SecItemAdd(keychainItem, nil)
    }
    
    private func retrieveCredential() -> (username: String?, password: String?) {
        var result: AnyObject?
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: "fudan.edu.cn",
            kSecReturnAttributes: true,
            kSecReturnData: true
        ] as CFDictionary
        
        let status = SecItemCopyMatching(query, &result)
        guard status == 0 && result != nil else { // check if retrieving succeeded
            return (nil, nil)
        }
        let dic = result as! NSDictionary
        let username = dic[kSecAttrAccount] as? String
        let password = String(data: dic[kSecValueData] as! Data, encoding: .utf8)!
        return (username, password)
    }
    
    private func deleteCredential() {
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: "fudan.edu.cn"
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}
