import SwiftUI
import FudanKit
import ViewUtils

struct AnnouncementCard: View {
    @ObservedObject private var campusModel = CampusModel.shared
    
    private let style = AsyncContentStyle {
        HStack {
            Text(verbatim: "关于2024年上海交通大学暑期学校面向C9成员高校学生开放选课的通知，关于2024年上海交通大学暑期学校面向C9成员高校学生开放选课的通知")
                .font(.callout)
                .lineLimit(3)
                .redacted(reason: .placeholder)
            Spacer()
        }
    } errorView: { error, retry in
        let errorDescription = (error as? LocalizedError)?.errorDescription ?? String(localized: "Loading Failed")
        
        Button(action: retry) {
            Label(errorDescription, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.secondary)
                .font(.system(size: 15))
        }
        .padding(.bottom, 15)
    }
    
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center) {
                HStack {
                    Image(systemName: "bell.fill")
                    
                    Text(campusModel.studentType == .undergrad ? "Undergraduate Academic Announcements" : "Postgraduate Academic Announcements")
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.pink)
                
                Spacer()
                
                AsyncContentView(style: style, animation: .default) {
                    switch(campusModel.studentType) {
                    case .undergrad:
                        let announcements = try await UndergraduateAnnouncementStore.shared.getCachedAnnouncements()
                        return Array(announcements.prefix(1))
                    default:
                        let announcements = try await PostgraduateAnnouncementStore.shared.getCachedAnnouncements()
                        return Array(announcements.prefix(1))
                    }
                } refreshAction: {
                    switch(campusModel.studentType) {
                    case .undergrad:
                        let announcements = try await UndergraduateAnnouncementStore.shared.getRefreshedAnnouncements()
                        return Array(announcements.prefix(1))
                    default:
                        let announcements = try await PostgraduateAnnouncementStore.shared.getRefreshedAnnouncements()
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
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
        .id(campusModel.studentType)
    }
}
