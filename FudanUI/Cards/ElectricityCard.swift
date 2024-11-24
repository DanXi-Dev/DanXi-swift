import SwiftUI
import FudanKit
import ViewUtils

struct ElectricityCard: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var contentId = UUID() // Controls refresh
    
    private let style = AsyncContentStyle {
        VStack(alignment: .leading) {
            Text(verbatim: "*******")
                .foregroundColor(.secondary)
                .bold()
                .font(.caption)
                .redacted(reason: .placeholder)
            
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(verbatim: "99.99")
                    .bold()
                    .font(.system(size: 25, design: .rounded))
                    .redacted(reason: .placeholder)
                
                Text(verbatim: " ")
                Text(verbatim: "kWh")
                    .foregroundColor(.secondary)
                    .bold()
                    .font(.caption2)
                    .redacted(reason: .placeholder)
                
                Spacer()
            }
        }
    } errorView: { error, retry in
        let errorDescription = (error as? LocalizedError)?.errorDescription ?? String(localized: "Loading Failed", bundle: .module)
        
        Button(action: retry) {
            Label(errorDescription, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.secondary)
                .font(.system(size: 15))
        }
        .padding(.bottom, 15)
    }
    
    private var content: some View {
        HStack(alignment: .bottom) {
            AsyncContentView(style: style, animation: .default) {
                async let usage = ElectricityStore.shared.getCachedElectricityUsage()
                async let dateValues = try? MyStore.shared.getCachedElectricityLogs().map({ DateValueChartData(date: $0.date, value: $0.usage) })
                return try await (usage, dateValues)
            } refreshAction: {
                async let usage = ElectricityStore.shared.getRefreshedEletricityUsage()
                async let dateValues = try? MyStore.shared.getRefreshedElectricityLogs().map({ DateValueChartData(date: $0.date, value: $0.usage) })
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
                        
                        Text(verbatim: " ")
                        Text(verbatim: "kWh")
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
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Dorm Electricity", bundle: .module)
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.green)
                
                Spacer()
                
                if #available(iOS 17.0, *) {
                    content
                        .id(contentId)
                        .onChange(of: scenePhase) { oldPhase, newPhase in
                            if oldPhase == .background {
                                Task(priority: .medium) {
                                    if await ElectricityStore.shared.outdated {
                                        await ElectricityStore.shared.clearCache()
                                        contentId = UUID()
                                    }
                                }
                            }
                        }
                } else {
                    content
                        .id(contentId)
                        .onChange(of: scenePhase) { newPhase in
                            if newPhase == .active {
                                Task(priority: .medium) {
                                    if await ElectricityStore.shared.outdated {
                                        await ElectricityStore.shared.clearCache()
                                        contentId = UUID()
                                    }
                                }
                            }
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
    ElectricityCard()
        .previewPrepared(wrapped: .card)
}
