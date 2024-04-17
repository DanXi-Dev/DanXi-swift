import WidgetKit
import SwiftUI
import FudanKit

struct BusWidgetProvier: TimelineProvider {
    func placeholder(in context: Context) -> BusEntry {
        BusEntry()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BusEntry) -> Void) {
        var entry = BusEntry()
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
                let entry = BusEntry(balance, transactions)
                let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            } catch {
                var entry = BusEntry()
                entry.loadFailed = true
                let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            }
        }
    }
}

struct BusEntry: TimelineEntry {
    let date: Date
    let balance: String
    let transactions: [FudanKit.Transaction]
    var placeholder = false
    var loadFailed = false
    
    init() {
        date = Date()
        balance = "100.0"
        transactions = []
    }
    
    init(_ balance: String, _ transactions: [FudanKit.Transaction]) {
        date = Date()
        self.balance = balance
        self.transactions = transactions
    }
}

public struct BusWidget: Widget {
    public init() { }
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ecard.fudan.edu.cn", provider: BusWidgetProvier()) { entry in
            BusWidgetView(entry: entry)
        }
        .configurationDisplayName("ECard")
        .description("Check ECard balance and transactions.")
        .supportedFamilies([.systemSmall])
    }
}

struct BusWidgetView: View {
    let entry: BusEntry
    
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
                    busContent.redacted(reason: .placeholder)
                } else {
                    busContent
                }
            }
        }
    }
    
    @ViewBuilder
    private var busContent: some View {
        Text("¥\(entry.balance)")
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

#Preview {
    BusWidgetView(entry: .init())
        .previewContext(WidgetPreviewContext(family: .systemSmall))
}
