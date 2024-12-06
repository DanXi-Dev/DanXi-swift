import Foundation

/// An error type that can locate the file and line number where it is thrown.
public struct LocatableError: Error {
    let file: String
    let line: Int
    let description: String?
    
    public init(_ description: String, file: String = #file, line: Int = #line) {
        self.file = file
        self.line = line
        self.description = description
    }
    
    public init(file: String = #file, line: Int = #line) {
        self.file = file
        self.line = line
        self.description = nil
    }
}

extension LocatableError: LocalizedError {
    public var errorDescription: String? {
        let url = URL(fileURLWithPath: file)
        let fileName = url.deletingPathExtension().lastPathComponent // remove path and .swift extension to shorten the length
        
        return if let description {
            "\(description) (\(fileName):\(String(line))"
        } else {
            String(localized: "Error (\(fileName):\(String(line)))", bundle: .module)
        }
    }
}
