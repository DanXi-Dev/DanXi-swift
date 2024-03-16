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
                
                ForEach(1..<4) { _ in
                    HStack {
                        Image(systemName: "info.circle")
                        Text("教务处通知内容")
                    }
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .lineLimit(1)
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
