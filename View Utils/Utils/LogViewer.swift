import SwiftUI

public func createRecord(_ content: String, file: StaticString = #file, line: UInt = #line) {
    Task { @MainActor in
        let date = Date()
        let record = Record(date: date, content: content, file: file, line: Int(line))
        EntryRecorder.shared.records.append(record)
    }
}

struct Record: Identifiable {
    let id = UUID()
    let date: Date
    let content: String
    let file: StaticString
    let line: Int
}

@MainActor
public class EntryRecorder: ObservableObject {
    static let shared = EntryRecorder()
    
    @Published var records: [Record] = []
}

public struct EntryViewer: View {
    @ObservedObject private var entryRecorder = EntryRecorder.shared
    
    public init() { }
    
    public var body: some View {
        List {
            ForEach(entryRecorder.records) { record in
                VStack(alignment: .leading) {
                    Text(record.content)
                    HStack {
                        Text("\(record.file):\(record.line)")
                        Spacer()
                        Text(record.date.formatted(date: .omitted, time: .shortened))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
