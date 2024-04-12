import SwiftUI
import FudanKit
import ViewUtils

struct ElectricityCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Dorm Electricity")
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.green)
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    AsyncContentView(animation: .default) {
                        async let usage = ElectricityStore.shared.getCachedElectricityUsage()
                        async let dateValues = try? MyStore.shared.getCachedElectricityLogs().map({ DateValueChartData(date: $0.date, value: $0.usage) })
                        return try await (usage, dateValues)
                    } content: {(info: ElectricityUsage, transactions: [DateValueChartData]?) in
                        VStack(alignment: .leading) {
                            Text(info.campus + info.building + info.room)
                                .foregroundColor(.secondary)
                                .bold()
                                .font(.caption)
                                .privacySensitive()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text(String(info.electricityAvailable))
                                    .bold()
                                    .font(.system(size: 25, design: .rounded))
                                    .privacySensitive()
                                
                                Text(" ")
                                Text("kWh")
                                    .foregroundColor(.secondary)
                                    .bold()
                                    .font(.caption2)
                                
                                Spacer()
                            }
                        }
                        
                        if let transactions {
                            DateValueChart(data: transactions.map({value in DateValueChartData(date: value.date, value: value.value)}), color: .green)
                                .frame(width: 100, height: 40)
                            
                            Spacer(minLength: 10)
                        }
                    } loadingView: {
                        AnyView(
                            VStack(alignment: .leading) {
                                Text("")
                                    .foregroundColor(.secondary)
                                    .bold()
                                    .font(.caption)
                                
                                HStack {
                                    Text("--.--")
                                        .bold()
                                        .font(.system(size: 25, design: .rounded))
                                    + Text(" ")
                                    + Text("kWh")
                                        .foregroundColor(.secondary)
                                        .bold()
                                        .font(.caption2)
                                    
                                    Spacer()
                                }
                            }
                        )
                    } failureView: { error, retryHandler in
                        let errorDescription = (error as? LocalizedError)?.errorDescription ?? String(localized: "Loading Failed")
                        return AnyView(
                            Button(action: retryHandler) {
                                Label(errorDescription, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15))
                            }
                                .padding(.bottom, 15)
                        )
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
    }
}
