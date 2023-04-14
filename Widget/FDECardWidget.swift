import WidgetKit
import SwiftUI

struct FDECardProvider: TimelineProvider {
    func placeholder(in context: Context) -> FDECardEntry {
        FDECardEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (FDECardEntry) -> Void) {
        var entry = FDECardEntry()
        if !context.isPreview {
            entry.placeholder = true
        }
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            do {
                try await FDECardAPI.getCSRF()
                let balance = try await FDECardAPI.getBalance()
                let transactions = try await FDECardAPI.getTransactions()
                let entry = FDECardEntry(balance, transactions)
                let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            } catch {
                var entry = FDECardEntry()
                entry.loadFailed = true
                let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            }
        }
    }
}

struct FDECardEntry: TimelineEntry {
    let date: Date
    let balance: String
    let transactions: [FDTransaction]
    var placeholder = false
    var loadFailed = false
    
    init() {
        date = Date()
        balance = "100.0"
        let sampleTransaction = FDTransaction(createTime: "", location: "食堂", amount: "10.0", balance: "")
        transactions = [sampleTransaction]
    }
    
    init(_ balance: String, _ transactions: [FDTransaction]) {
        date = Date()
        self.balance = balance
        self.transactions = transactions
    }
}

struct FDECardWidget: Widget {
    let kind: String = "ecard.fudan.edu.cn"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ecard.fudan.edu.cn", provider: FDECardProvider()) { entry in
            FDECardView(entry: entry)
        }
        .configurationDisplayName("ECard")
        .description("Check ECard balance and transactions.")
        .supportedFamilies([.systemSmall])
    }
}

struct FDECardView: View {
    var entry: FDECardEntry

    var body: some View {
        Group {
            if entry.loadFailed {
                Text("Load Failed")
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Label("ECard", systemImage: "creditcard.fill")
                            .bold()
                            .font(.callout)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    if entry.placeholder {
                        content.redacted(reason: .placeholder)
                    } else {
                        content
                    }
                }
                .padding()
            }
        }
        .widgetURL(URL(string: "fduhole://campus/ecard"))
    }
    
    @ViewBuilder
    private var content: some View {
        Text("¥\(entry.balance)")
            .bold()
            .font(.title2)
            .foregroundColor(.primary.opacity(0.7))

        Spacer()
        
        if let transaction = entry.transactions.first {
            Label("\(transaction.location) \(transaction.amount)", systemImage: "clock")
                .bold()
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
}

struct FDECardView_Previews: PreviewProvider {
    static var previews: some View {
        FDECardView(entry: FDECardEntry())
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
