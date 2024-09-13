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
                let balance = try await WalletAPI.getBalance()
                let transactions = try await WalletAPI.getTransactions(page: 1)
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
        transactions = []
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
        }
        .configurationDisplayName(String(localized: "ECard", bundle: .module))
        .description(String(localized: "Check ECard balance and transactions.", bundle: .module))
        .supportedFamilies([.systemSmall])
    }
}

struct WalletWidgetView: View {
    let entry: WalletEntry
    
    var body: some View {
        if #available(iOS 17, *) {
            widgetContent
                .containerBackground(.fill, for: .widget)
        } else {
            widgetContent
                .padding()
        }
    }
    
    @ViewBuilder
    private var widgetContent: some View {
        if entry.loadFailed {
            Text("Load Failed", bundle: .module)
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Label(String(localized: "ECard", bundle: .module), systemImage: "creditcard.fill")
                        .bold()
                        .font(.callout)
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                if entry.placeholder {
                    walletContent.redacted(reason: .placeholder)
                } else {
                    walletContent
                }
            }
        }
    }
    
    @ViewBuilder
    private var walletContent: some View {
        Text(verbatim: "¥\(entry.balance)")
            .bold()
            .font(.title2)
            .foregroundColor(.primary.opacity(0.7))

        Spacer()
        
        if let transaction = entry.transactions.first {
            Label("\(transaction.location) \(String(format:"%.2f",transaction.amount))", systemImage: "clock")
                .bold()
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
}
