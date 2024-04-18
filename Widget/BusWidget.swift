import FudanKit
import SwiftUI
import WidgetKit

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
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
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

public struct BusEntry: TimelineEntry {
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

public struct BusWidget: Widget {
    public init() {}
    
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
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Handan")
                        Text("to Fenglin")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "bus.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                Text("10:00")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Due in 1 min")
                    .font(.callout)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .foregroundStyle(.green)
                
                Text("next 11:30")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                
            }
        }
    }
}

@available(iOS 17, *)
#Preview(as: .systemSmall) {
    BusWidget()
} timeline: {
    return [BusEntry(), BusEntry()]
}
