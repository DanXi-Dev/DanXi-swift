import SwiftUI

struct FDECardCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("ECard")
                        Spacer()
                    }
                    .bold()
                    .font(.callout)
                    .foregroundColor(.orange)
                    
                    Text("¥25.00")
                        .bold()
                        .font(.title2)
                        .foregroundColor(.primary.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Spacer()
                    
                    ForEach(1..<4) { _ in
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                            Text("食堂 10.00")
                        }
                        .bold()
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
        .frame(height: 75)
    }
}

#Preview {
    List {
        FDECardCard()
    }
}
