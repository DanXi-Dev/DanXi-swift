import SwiftUI
import FudanKit

struct FDECardCard: View {
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
                        async let dateValues = MyStore.shared.getCachedWalletLogs().map({ FDDateValueChartData(date: $0.date, value: $0.amount) })
                        return try await (balance, dateValues)
                    } content: {(balance: String, transactions: [FDDateValueChartData]) in
                        VStack(alignment: .leading) {
                            Text("Balance")
                                .foregroundColor(.secondary)
                                .bold()
                                .font(.caption)
                            
                            HStack(alignment: .bottom) {
                                Text(balance)
                                    .bold()
                                    .font(.system(size: 25, design: .rounded))
                                + Text(" ")
                                + Text("Yuan")
                                    .foregroundColor(.secondary)
                                    .bold()
                                    .font(.caption2)
                                
                                
                                Spacer()
                            }
                            
                        }
                                                    
                        FDDateValueChart(data: transactions.map({value in FDDateValueChartData(date: value.date, value: value.value)}), color: .orange)
                            .frame(width: 100, height: 40)
                        
                        Spacer(minLength: 10)
                    } loadingView: {
                        AnyView(
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("")
                                        .foregroundColor(.gray)
                                        .bold()
                                        .font(.caption)
                                    
                                    Text("--.--")
                                        .bold()
                                        .font(.system(size: 25, design: .rounded))
                                    
                                    + Text(" ")

                                    + Text("Yuan")
                                        .foregroundColor(.secondary)
                                        .bold()
                                        .font(.caption2)
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

#Preview {
    List {
        FDECardCard()
            .frame(height: 85)
    }
}
