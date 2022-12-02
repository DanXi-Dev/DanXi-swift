import Foundation

struct PreviewDecode {    
    static func decodeObj<T: Decodable>(name: String) -> T? {
        guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
    
    static func decodeList<T: Decodable>(name: String) -> [T] {
        guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            return []
        }
    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    func decodeData<T: Decodable>(_ name: String) -> T {
        let path = path(forResource: name, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return try! JSONDecoder().decode(T.self, from: data)
    }
}
