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
