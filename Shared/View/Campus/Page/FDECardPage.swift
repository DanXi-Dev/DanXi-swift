import Charts
import FudanKit
import SwiftUI

struct FDECardPage: View {
    var body: some View {
        AsyncContentView {
            async let balance = MyStore.shared.getCachedUserInfo().balance
            async let dateValues = MyStore.shared.getCachedWalletLogs()
                .map { FDDateValueChartData(date: $0.date, value: $0.amount) }
            
            let (balanceLoaded, dateValuesLoaded) = try await (balance, dateValues)
            
            let filteredDateValues = Array(FDDateValueChartData.formattedData(dateValuesLoaded)[0 ..< min(7, dateValuesLoaded.count)])
            
            return (balanceLoaded, filteredDateValues)
        } content: { balance, history in
            ECardPageContent(balance: balance, history: history)
        }
    }
}

private struct ECardPageContent: View {
    let balance: String
    let history: [FDDateValueChartData]
    
    @State private var showDetailedTransactionHistory = false
    
    var body: some View {
        List {
            Section {
                LabeledContent("ECard Balance", value: "¥ \(balance)")
            }
            
            if #available(iOS 17, *) {
                FDEcardPageChart(data: history)
            }
            
            if showDetailedTransactionHistory {
                AsyncCollection { _ in
                    try await WalletStore.shared.getCachedTransactions()
                } content: { (transaction: FudanKit.Transaction) in
                    TransactionView(transaction: transaction)
                }
            } else {
                Section {
                    Button(action: {
                        showDetailedTransactionHistory = true
                    }, label: {
                        Text("Show Transaction History")
                    })
                }
            }
        }
        .navigationTitle("ECard Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TransactionView: View {
    let transaction: FudanKit.Transaction
    
    var body: some View {
        LabeledContent {
            Text("¥\(String(format: "%.2f", transaction.amount))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        } label: {
            VStack(alignment: .leading) {
                Text(transaction.location)
                Text(transaction.date.formatted(.dateTime.day().month().year().hour().minute()))
                    .foregroundColor(.secondary)
                    .font(.callout)
            }
        }
    }
}

@available(iOS 17.0, *)
private struct FDEcardPageChart: View {
    let data: [FDDateValueChartData]
    @State private var chartSelection: Date?
    
    private var areaBackground: Gradient {
        return Gradient(colors: [.orange.opacity(0.5), .clear])
    }
    
    var body: some View {
        Section("Daily Spending") {
            Chart {
                ForEach(data) { d in
                    LineMark(
                        x: .value("Date", d.date, unit: .day),
                        y: .value("¥", d.value)
                    )
                    
                    AreaMark(
                        x: .value("Date", d.date, unit: .day),
                        y: .value("", d.value)
                    )
                    .foregroundStyle(areaBackground)
                }
                
                if let selectedDate = chartSelection,
                   let selectedData = data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
                {
                    RuleMark(x: .value("Date", selectedDate, unit: .day))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .foregroundStyle(.secondary)
                        .annotation(
                            position: .top, spacing: 0,
                            overflowResolution: .init(
                                x: .fit(to: .chart),
                                y: .disabled
                            )
                        ) {
                            VStack {
                                Text("\(selectedData.date, format: .dateTime.day().month())")
                                    .foregroundStyle(.secondary)
                                Text("¥ \(String(format: "%.2f", selectedData.value))")
                                    .font(.headline)
                            }
                            .fixedSize()
                            .font(.system(.caption, design: .rounded))
                            .padding(.bottom, 1)
                        }
                    PointMark(
                        x: .value("Date", selectedData.date, unit: .day),
                        y: .value("kWh", selectedData.value)
                    )
                    .symbolSize(70)
                    .foregroundStyle(Color.secondarySystemGroupedBackground)
                    PointMark(
                        x: .value("Date", selectedData.date, unit: .day),
                        y: .value("Yuan", selectedData.value)
                    )
                    .symbolSize(40)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                }
            }
            .chartYAxisLabel(String(localized: "Yuan"))
            .frame(height: 200)
            .chartXSelection(value: $chartSelection)
            .foregroundColor(.orange)
        }
        .padding(.top, 8) // Leave space for annotation
    }
}
