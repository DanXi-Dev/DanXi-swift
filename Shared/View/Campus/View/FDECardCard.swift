import SwiftUI

struct FDECardCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top) {
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
                    
                    AsyncContentView(animation: .default) {
                        return try await FDECardAPI.getBalance()
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
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Spacer()
                    
                    AsyncContentView(animation: .default) {
                        try await FDECardAPI.getCSRF()
                        let transactions = try await FDECardAPI.getTransactions()
                        return Array(transactions.prefix(1))
                    } content: { (transactions: [FDTransaction]) in
                        ForEach(transactions) { transaction in
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                Text("\(transaction.location) \(transaction.amount)")
                            }
                            .bold()
                            .font(.footnote)
                            .foregroundColor(.orange)
                        }
                    } loadingView: {
                        AnyView(HStack(spacing: 3) {
                            Image(systemName: "clock")
                            Text("--")
                        }
                            .bold()
                            .font(.footnote)
                            .foregroundColor(.orange))
                    } failureView: { error, retryHandler in AnyView(
                        Button(action: retryHandler) {
                            AnyView(HStack(spacing: 3) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("--")
                            }
                                .bold()
                                .font(.footnote)
                                .foregroundColor(.orange))
                        }
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
