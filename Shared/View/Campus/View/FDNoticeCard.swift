import SwiftUI

struct FDNoticeCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "bell.fill")
                    Text("Academic Office Announcements")
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.pink)
                
                Spacer()
                
                AsyncContentView { 
                    return try await FDNoticeAPI.getNoticeList(1)
                } content: { (notices: [FDNotice]) in
                    ForEach(1..<3) { i in
                        Text(notices[i].title)
                        .font(.callout)
                        .lineLimit(2)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
        .frame(height: 100)
    }
}

#Preview {
    List {
        FDNoticeCard()
    }
}
