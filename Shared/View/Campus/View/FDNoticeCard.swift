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
                
                AsyncContentView(style: .widget) {
                    let notifications = try await FDNoticeAPI.getNoticeList(1)
                    return Array(notifications.prefix(1))
                } content: { (notices: [FDNotice]) in
                    ForEach(notices) { notice in
                        Text(notice.title)
                            .font(.callout)
                            .lineLimit(3)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
        .frame(height: 85)
    }
}

#Preview {
    List {
        FDNoticeCard()
    }
}
