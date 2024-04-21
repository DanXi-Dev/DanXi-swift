import Charts
import ViewUtils
import FudanKit
import SwiftUI

struct ElectricityPage: View {
    var body: some View {
        AsyncContentView(animation: .default) { forceReload in
            async let usage = forceReload ? ElectricityStore.shared.getRefreshedEletricityUsage() : ElectricityStore.shared.getCachedElectricityUsage()
            async let dateValues = try? (forceReload ? MyStore.shared.getRefreshedElectricityLogs() : MyStore.shared.getCachedElectricityLogs()).map { DateValueChartData(date: $0.date, value: $0.usage) }
            
            let (usageLoaded, dateValuesLoaded) = try await (usage, dateValues)
            
            if let dateValuesLoaded {
                let filteredDateValues = Array(DateValueChartData.formattedData(dateValuesLoaded)[0 ..< min(7, dateValuesLoaded.count)])
                return (usageLoaded, filteredDateValues)
            } else {
                return (usageLoaded, dateValuesLoaded)
            }
        } content: { (info: ElectricityUsage, transactions: [DateValueChartData]?) in
            List {
                LabeledContent {
                    Text(info.campus)
                } label: {
                    Text("Campus")
                }
                
                LabeledContent {
                    Text(info.building + info.room)
                } label: {
                    Text("Dorm")
                }
                
                LabeledContent {
                    Text(ElectricityUsage.convertEnergyToMeasuredString(info.electricityAvailable))
                } label: {
                    Text("Electricity Available")
                }
                
                LabeledContent {
                    Text(ElectricityUsage.convertEnergyToMeasuredString(info.electricityUsed))
                } label: {
                    Text("Electricity Used")
                }
                
                if #available(iOS 17, *), let transactions {
                    ElectricityPageChart(data: transactions)
                }
            }
        }
        .navigationTitle("Dorm Electricity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct ElectricityPageChart: View {
    let data: [DateValueChartData]
    @State private var chartSelection: Date?
    
    private var areaBackground: Gradient {
        return Gradient(colors: [.green.opacity(0.5), .clear])
    }
    
    var body: some View {
        Section("Electricity Usage History") {
            Chart {
                ForEach(data) { d in
                    LineMark(
                        x: .value("Date", d.date, unit: .day),
                        y: .value("kWh", d.value)
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
                                Text(ElectricityUsage.convertEnergyToMeasuredString(selectedData.value))
                                    .font(.subheadline)
                                    .bold()
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
                    .foregroundStyle(Color(uiColor: .secondarySystemGroupedBackground))
                    PointMark(
                        x: .value("Date", selectedData.date, unit: .day),
                        y: .value("kWh", selectedData.value)
                    )
                    .symbolSize(40)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                }
            }
            .chartYAxisLabel(String(localized: "kWh"))
            .frame(height: 200)
            .chartXSelection(value: $chartSelection)
            .foregroundColor(.green)
        }
        .padding(.top, 8) // Leave space for annotation
    }
}
