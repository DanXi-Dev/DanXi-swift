import SwiftUI
import FudanKit
import ViewUtils

struct AnnouncementCard: View {
    @ObservedObject private var campusModel = CampusModel.shared
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center) {
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
                    switch(campusModel.studentType) {
                    case .undergrad:
                        let announcements = try await UndergraduateAnnouncementStore.shared.getCachedAnnouncements()
                        return Array(announcements.prefix(1))
                    default:
                        let announcements = try await PostgraduateAnnouncementStore.shared.getCachedAnnouncements()
                        return Array(announcements.prefix(1))
                    }
                } content: { (annoucements: [Announcement]) in
                    ForEach(annoucements) { announcement in
                        HStack {
                            Text(announcement.title)
                                .font(.callout)
                                .lineLimit(3)
                            Spacer()
                        }
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
                    let errorDescription = (error as? LocalizedError)?.errorDescription ?? String(localized: "Loading Failed")
                    return AnyView(
                        Button(action: retryHandler) {
                            Label(errorDescription, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 15))
                        }
                            .padding(.bottom, 15)
                    )
                }
                .id(campusModel.studentType)
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
    }
}
