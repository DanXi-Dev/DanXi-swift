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
                    let notifications = try await FDNoticeAPI.getNoticeList(1)
                    return Array(notifications.prefix(1))
                } content: { (notices: [FDNotice]) in
                    ForEach(notices) { notice in
                        Text(notice.title)
                            .font(.callout)
                            .lineLimit(3)
                    }
                } loadingView: {
                    AnyView(ProgressView()
                        .padding(.bottom, 15))
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
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
    }
}

#Preview {
    List {
        FDNoticeCard()
            .frame(height: 85)
    }
}
