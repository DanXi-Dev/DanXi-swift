import WidgetKit
import SwiftUI
import FudanKit

struct WalletWidgetProvier: TimelineProvider {
    func placeholder(in context: Context) -> WalletEntry {
        WalletEntry()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WalletEntry) -> Void) {
        var entry = WalletEntry()
        if !context.isPreview {
            entry.placeholder = true
        }
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            do {
                let (balance, transactions) = try await (WalletAPI.getBalance(), WalletAPI.getTransactions(page: 1))
                let entry = WalletEntry(balance, transactions)
                let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            } catch {
                var entry = WalletEntry()
                entry.loadFailed = true
                let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            }
        }
    }
}

public struct WalletEntry: TimelineEntry {
    public let date: Date
    public let balance: String
    public let transactions: [FudanKit.Transaction]
    public var placeholder = false
    public var loadFailed = false
    
    public init() {
        date = Date()
        balance = "100.0"
        transactions = [
            Transaction(id: UUID(), date: Date.now, location: "江湾校区食堂1楼", amount: 10.00, remaining: 200.00),
            Transaction(id: UUID(), date: Date.now, location: "江湾校区食堂2楼", amount: 20.00, remaining: 210.00)
        ]
    }
    
    public init(_ balance: String, _ transactions: [FudanKit.Transaction]) {
        date = Date()
        self.balance = balance
        self.transactions = transactions
    }
}

public struct WalletWidget: Widget {
    public init() { }
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ecard.fudan.edu.cn", provider: WalletWidgetProvier()) { entry in
            WalletWidgetView(entry: entry)
                .widgetURL(URL(string: "fduhole://navigation/campus?section=wallet")!)
        }
        .configurationDisplayName("ECard")
        .description("Check ECard balance and transactions.")
        .supportedFamilies([.systemSmall])
    }
}

struct WalletWidgetView: View {
    let entry: WalletEntry
    
    var body: some View {
        WidgetWrapper(failed: entry.loadFailed) {
            VStack(alignment: .leading) {
                HStack {
                    Label("ECard", systemImage: "creditcard.fill")
                        .bold()
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.bottom, 6)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Balance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(verbatim: "¥\(entry.balance)")
                        .bold()
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                Spacer(minLength: 6)
                
                ForEach(entry.transactions.prefix(2), id: \.id) { transaction in
                    VStack(alignment: .leading) {
                        Text(verbatim: "\(transaction.location)")
                            .lineLimit(1)
                        
                        HStack {
                            Text(verbatim: "¥\(String(format:"%.2f",transaction.amount))")
                            Spacer()
                            Text(transaction.date, style: .time)
                        }
                        .foregroundColor(.secondary)
                    }
                    .font(.footnote)
                }
            }
        }
    }
}

@available(iOS 17, *)
#Preview("Wallet", as: .systemSmall) {
    WalletWidget()
} timeline: {
    WalletEntry()
}
