import SwiftUI

public func createRecord(_ content: String, file: String = #file, line: UInt = #line) {
    Task { @MainActor in
        let date = Date()
        let record = Record(date: date, content: content, file: file, line: Int(line))
        EntryRecorder.shared.records.append(record)
    }
}

public struct Record: Identifiable {
    public let id = UUID()
    public let date: Date
    public let content: String
    public let file: String
    public let line: Int
}

@MainActor
public class EntryRecorder: ObservableObject {
    public static let shared = EntryRecorder()
    
    @Published public var records: [Record] = []
}
