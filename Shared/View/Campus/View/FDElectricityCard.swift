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
                        return try await ElectricityStore.shared.getCachedElectricityUsage()
                    } content: { info in
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
                        let errorDescription = (error as? LocalizedError)?.errorDescription ?? "Loading Failed"
                        return AnyView(
                            Button(action: retryHandler) {
                                Label(errorDescription, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15))
                            }
                                .padding(.bottom, 15)
                        )
                    }
                    
                    Spacer()
                    
                    AsyncContentView(animation: .default) {
                        try await ElectricityStore.shared.getCachedDailyElectricityHistory().map({v in FDDateValueChartData(date: v.date, value: v.value)})
                    } content: { (transactions: [FDDateValueChartData]) in
                        FDDateValueChart(data: transactions.map({value in FDDateValueChartData(date: value.date, value: value.value)}))
                            .frame(width: 80, height: 40)
                            .foregroundColor(.green)
                    } loadingView: {
                        AnyView(ProgressView())
                    } failureView: { error, retryHandler in AnyView(Text(error.localizedDescription))
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
