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
                    .foregroundColor(.danxiDeepOrange)
                    
                    Spacer()
                    
                    Text("Balance")
                        .foregroundColor(.danxiGrey)
                        .bold()
                        .font(.subheadline)
                    
                    AsyncContentView{
                        return try await FDECardAPI.getBalance()
                    } content: { (balance: String) in
                        Text(balance)
                            .bold()
                            .font(.title2)
                            .foregroundColor(.primary)
                        + Text(" ¥")
                            .bold()
                            .font(.subheadline)
                            .foregroundColor(.danxiGrey)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Spacer()
                    
                    AsyncContentView {
                        try await FDECardAPI.getCSRF()
                        let transactions = try await FDECardAPI.getTransactions()
                        return transactions
                    } content: { (transactions: [FDTransaction]) in
                        if !transactions.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                Text("\(transactions[0].location) \(transactions[0].amount)")
                            }
                            .bold()
                            .font(.footnote)
                            .foregroundColor(.danxiDeepOrange)
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
    List {
        FDECardCard()
            .frame(height: 85)
    }
}
