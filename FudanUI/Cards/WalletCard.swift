import SwiftUI
import FudanKit
import ViewUtils

struct WalletCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center) {
                HStack {
                    Image(systemName: "creditcard.fill")
                    Text("ECard")
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.orange)
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    AsyncContentView(animation: .default) {
                        async let balance = MyStore.shared.getCachedUserInfo().balance
                        async let dateValues = MyStore.shared.getCachedWalletLogs().map({ DateValueChartData(date: $0.date, value: $0.amount) })
                        return try await (balance, dateValues)
                    } content: {(balance: String, transactions: [DateValueChartData]) in
                        VStack(alignment: .leading) {
                            Text("Balance")
                                .foregroundColor(.secondary)
                                .bold()
                                .font(.caption)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text(balance)
                                    .bold()
                                    .font(.system(size: 25, design: .rounded))
                                    .privacySensitive()
                                
                                Text(" ")
                                Text("Yuan")
                                    .foregroundColor(.secondary)
                                    .bold()
                                    .font(.caption2)
                                
                                Spacer()
                            }
                        }
                        
                        DateValueChart(data: transactions.map({value in DateValueChartData(date: value.date, value: value.value)}), color: .orange)
                            .frame(width: 100, height: 40)
                        
                        Spacer(minLength: 10)
                    } loadingView: {
                        AnyView(
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Balance")
                                        .foregroundColor(.secondary)
                                        .bold()
                                        .font(.caption)
                                        .redacted(reason: .placeholder)
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                                        Text("99.99")
                                            .bold()
                                            .font(.system(size: 25, design: .rounded))
                                            .redacted(reason: .placeholder)
                                        
                                        Text(" ")
                                        Text("Yuan")
                                            .foregroundColor(.secondary)
                                            .bold()
                                            .font(.caption2)
                                            .redacted(reason: .placeholder)
                                        
                                        Spacer()
                                    }
                                }
                                Spacer()
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
