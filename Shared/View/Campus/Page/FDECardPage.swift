import SwiftUI

struct FDECardPage: View {    
    var body: some View {
        AsyncContentView { () -> String in
            let balance = try await FDECardAPI.getBalance()
            try await FDECardAPI.getCSRF()
            return balance
        } content: { balance in
            ECardPageContent(balance: balance)
        }
    }
}

fileprivate struct ECardPageContent: View {
    let balance: String
    @State private var page = 1
    
    var body: some View {
        List {
            Section {
                LabeledContent("ECard Balance", value: balance)
            }
            
            AsyncCollection { _ in
                let transactions = try await FDECardAPI.getTransactions(page: page)
                page += 1
                return transactions
            } content: { (transaction: FDTransaction) in
                TransactionView(transaction: transaction)
            }
        }
        .navigationTitle("ECard Information")
    }
}

fileprivate struct TransactionView: View {
    let transaction: FDTransaction
    
    var body: some View {
        LabeledContent {
            Text(transaction.amount)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        } label: {
            VStack(alignment: .leading) {
                Text(transaction.location)
                Text(transaction.createTime)
                    .foregroundColor(.secondary)
                    .font(.callout)
            }
        }
    }
}
