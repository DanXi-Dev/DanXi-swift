import SwiftUI
import FudanKit
import ViewUtils

struct WalletCard: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var contentId = UUID() // Controls refresh
    
    private let style = AsyncContentStyle {
        HStack {
            VStack(alignment: .leading) {
                Text("Balance", bundle: .module)
                    .foregroundColor(.secondary)
                    .bold()
                    .font(.caption)
                    .redacted(reason: .placeholder)
                
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(verbatim: "00.00")
                        .bold()
                        .font(.system(size: 25, design: .rounded))
                        .redacted(reason: .placeholder)
                    
                    Text(verbatim: " ")
                    Text("Yuan", bundle: .module)
                        .foregroundColor(.secondary)
                        .bold()
                        .font(.caption2)
                        .redacted(reason: .placeholder)
                    
                    Spacer()
                }
            }
            Spacer()
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
                let content = try await WalletStore.shared.getCachedContent()
                let dateValues = content.logs.map { DateValueChartData(date: $0.date, value: $0.amount) }
                return (content.balance, dateValues)
            } content: { (balance: String, transactions: [DateValueChartData]) in
                VStack(alignment: .leading) {
                    Text("Balance", bundle: .module)
                        .foregroundColor(.secondary)
                        .bold()
                        .font(.caption)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(balance)
                            .bold()
                            .font(.system(size: 25, design: .rounded))
                            .privacySensitive()
                        
                        Text(verbatim: " ")
                        Text("Yuan", bundle: .module)
                            .foregroundColor(.secondary)
                            .bold()
                            .font(.caption2)
                        
                        Spacer()
                    }
                }
                
                DateValueChart(data: transactions.map({value in DateValueChartData(date: value.date, value: value.value)}), color: .orange)
                    .frame(width: 100, height: 40)
                
                Spacer(minLength: 10)
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center) {
                HStack {
                    Image(systemName: "creditcard.fill")
                    Text("ECard", bundle: .module)
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.orange)
                
                Spacer()
                
                if #available(iOS 17.0, *) {
                    content
                        .id(contentId)
                        .onChange(of: scenePhase) { oldPhase, newPhase in
                            if oldPhase == .background {
                                Task(priority: .medium) {
                                    if await MyStore.shared.outdated {
                                        await MyStore.shared.clearCache()
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
                                    if await MyStore.shared.outdated {
                                        await MyStore.shared.clearCache()
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

// TODO: Restore new WalletCard preview
//#Preview {
//    WalletCard()
//        .previewPrepared(wrapped: .card)
//}
