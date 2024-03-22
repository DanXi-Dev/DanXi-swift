import SwiftUI
import FudanKit

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
                
                AsyncContentView(animation: .default) {
                    let announcements = try await AnnouncementStore.shared.getCachedAnnouncements()
                    return Array(announcements.prefix(1))
                } content: { (annoucements: [Announcement]) in
                    ForEach(annoucements) { announcement in
                        Text(announcement.title)
                            .font(.callout)
                            .lineLimit(3)
                    }
                } loadingView: {
                    AnyView(                
                        VStack(alignment: .leading) {
                        Rectangle()
                            .foregroundColor(.gray)
                            .opacity(0.2)
                            .frame(height: 18)
                        Rectangle()
                            .foregroundColor(.gray)
                            .opacity(0.2)
                            .frame(width: 70, height: 18)
                    })
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
