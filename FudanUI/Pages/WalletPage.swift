import Charts
import FudanKit
import SwiftUI
import ViewUtils

struct WalletPage: View {
    var body: some View {
        AsyncContentView {
            return try await WalletStore.shared.getCachedContent()
        } refreshAction: {
            return try await WalletStore.shared.getRefreshedContent()
        } content: { content in
            WalletPageContent(content: content)
        }
        .navigationTitle(String(localized: "ECard Information", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WalletPageContent: View {
    let content: WalletContent
    
    @State private var showDetailedTransactionHistory = false
    
    private var filteredDateValues: [DateValueChartData] {
        let dateValues = content.logs.map { DateValueChartData(date: $0.date, value: $0.amount) }
        return Array(DateValueChartData.formattedData(dateValues)[0 ..< min(7, dateValues.count)])
    }
    
    var body: some View {
        List {
            Section {
                LabeledContent {
                    Text(verbatim: "¥ \(content.balance)")
                } label: {
                    Text("ECard Balance", bundle: .module)
                }
            }
            
            if #available(iOS 17, *), !filteredDateValues.isEmpty {
                WalletPageChart(data: filteredDateValues)
            }
            
            Section {
                ForEach(content.transactions) { transaction in
                    TransactionView(transaction: transaction)
                }
            }
        }
    }
}

private struct TransactionView: View {
    let transaction: FudanKit.Transaction
    
    var body: some View {
        
        LabeledContent {
            Text(verbatim: "\(transaction.sign)¥\(String(format: "%.2f", transaction.amount))")
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
private struct WalletPageChart: View {
    let data: [DateValueChartData]
    @State private var chartSelection: Date?
    
    private var areaBackground: Gradient {
        return Gradient(colors: [.orange.opacity(0.5), .clear])
    }
    
    var body: some View {
        Section {
            Chart {
                ForEach(data) { d in
                    LineMark(
                        x: .value(String(localized: "Date", bundle: .module), d.date, unit: .day),
                        y: .value(String("¥"), d.value)
                    )
                    
                    AreaMark(
                        x: .value(String(localized: "Date", bundle: .module), d.date, unit: .day),
                        y: .value(String(""), d.value)
                    )
                    .foregroundStyle(areaBackground)
                }
                
                if let selectedDate = chartSelection,
                   let selectedData = data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
                {
                    RuleMark(x: .value(String(localized: "Date", bundle: .module), selectedDate, unit: .day))
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
                                Text(verbatim: "¥ \(String(format: "%.2f", selectedData.value))")
                                    .font(.headline)
                            }
                            .fixedSize()
                            .font(.system(.caption, design: .rounded))
                            .padding(.bottom, 1)
                        }
                    PointMark(
                        x: .value(String(localized: "Date", bundle: .module), selectedData.date, unit: .day),
                        y: .value("kWh", selectedData.value)
                    )
                    .symbolSize(70)
                    #if !os(watchOS)
                    .foregroundStyle(Color(uiColor: .secondarySystemGroupedBackground))
                    #endif
                    PointMark(
                        x: .value(String(localized: "Date", bundle: .module), selectedData.date, unit: .day),
                        y: .value(String(localized: "Yuan", bundle: .module), selectedData.value)
                    )
                    .symbolSize(40)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                }
            }
            .chartYAxisLabel(String(localized: "Yuan", bundle: .module))
            .frame(height: 200)
            .chartXSelection(value: $chartSelection)
            .foregroundColor(.orange)
        } header: {
            Text("Daily Spending", bundle: .module)
        }
        .padding(.top, 8) // Leave space for annotation
    }
}

#Preview {
    WalletPage()
        .previewPrepared()
}
