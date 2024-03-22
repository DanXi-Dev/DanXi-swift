import SwiftUI
import FudanKit

struct FDECardCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
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
                        try await (WalletStore.shared.getCachedUserInfo().balance,
                                   WalletStore.shared.getCachedDailyTransactionHistory().map({value in 
                                                                        FDDateValueChartData(date: value.date, value: value.value)}))
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
                                + Text("yuan")
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
                                    + Text("yuan")
                                        .foregroundColor(.secondary)
                                        .bold()
                                        .font(.caption2)
                                    
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
