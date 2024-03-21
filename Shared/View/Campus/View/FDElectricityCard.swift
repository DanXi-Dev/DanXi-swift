import SwiftUI
import FudanKit

struct FDElectricityCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Image(systemName: "powercord.fill")
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
                        async let dateValues = MyStore.shared.getCachedElectricityLogs().map({ FDDateValueChartData(date: $0.date, value: $0.usage) })
                        return try await (usage, dateValues)
                    } content: {(info: ElectricityUsage, transactions: [FDDateValueChartData]) in
                        VStack(alignment: .leading) {
                            Text(info.campus + info.building + info.room)
                                .foregroundColor(.secondary)
                                .bold()
                                .font(.caption)
                            
                            HStack(alignment: .bottom) {
                                Text(String(info.electricityAvailable))
                                    .bold()
                                    .font(.system(size: 25, design: .rounded))
                                +
                                Text(" kWh")
                                    .foregroundColor(.secondary)
                                    .bold()
                                    .font(.callout)
                                
                                Spacer()
                            }
                        }
                        
                        Spacer()
                        
                        FDDateValueChart(data: transactions.map({value in FDDateValueChartData(date: value.date, value: value.value)}), color: .green)
                            .frame(width: 100, height: 40)
                    } loadingView: {
                        AnyView(
                            VStack(alignment: .leading) {
                                Text("")
                                    .foregroundColor(.secondary)
                                    .bold()
                                    .font(.caption)
                                
                                HStack(alignment: .bottom) {
                                    Text("--.--")
                                        .bold()
                                        .font(.system(size: 25, design: .rounded))
                                    +
                                    Text(" kWh")
                                        .foregroundColor(.secondary)
                                        .bold()
                                        .font(.callout)
                                    
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

#Preview {
    List {
        FDElectricityCard()
            .frame(height: 85)
    }
}
