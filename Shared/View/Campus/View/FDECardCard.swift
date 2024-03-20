import SwiftUI
import FudanKit

struct FDECardCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {
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
                        return try await WalletStore.shared.getCachedUserInfo().balance
                    } content: { (balance: String) in
                        VStack(alignment: .leading) {
                            Text("Balance")
                                .foregroundColor(.gray)
                                .bold()
                                .font(.subheadline)
                            
                            Text(balance)
                                .bold()
                                .font(.title2)
                                .foregroundColor(.primary)
                            + Text(" yuan")
                                .bold()
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } loadingView: {
                        AnyView(
                            VStack(alignment: .leading) {
                                Text("Balance")
                                    .foregroundColor(.gray)
                                    .bold()
                                    .font(.subheadline)
                                
                                Text("--.--")
                                    .bold()
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                + Text(" yuan")
                                    .bold()
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
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
                        try await WalletStore.shared.getCachedDailyTransactionHistory().map({value in FDDateValueChartData(date: value.date, value: value.value)})
                    } content: { (transactions: [FDDateValueChartData]) in
                        FDDateValueChart(data: transactions, color: .orange)
                            .frame(width: 100, height: 40)
                    } loadingView: {
                        AnyView(ProgressView())
                    } failureView: { error, retryHandler in AnyView(EmptyView())
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
