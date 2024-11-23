import SwiftUI
import FudanKit
import ViewUtils

struct AnnouncementCard: View {
    @ObservedObject private var campusModel = CampusModel.shared
    @Environment(\.scenePhase) var scenePhase
    @State private var contentId = UUID() // Controls refresh
    
    private let style = AsyncContentStyle {
        HStack {
            Text(verbatim: String(repeating: "*", count: 25))
                .font(.callout)
                .lineLimit(3)
                .redacted(reason: .placeholder)
            Spacer()
        }
    } errorView: { error, retry in
        let errorDescription = (error as? LocalizedError)?.errorDescription ?? String(localized: "Loading Failed", bundle: .module)
        
        Button(action: retry) {
            Label(errorDescription, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.secondary)
                .font(.system(size: 15))
        }
        .padding(.bottom, 15)
    }
    
    private var content: some View {
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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center) {
                HStack {
                    Image(systemName: "bell.fill")
                    
                    Text(campusModel.studentType == .undergrad ? "Undergraduate Academic Announcements" : "Postgraduate Academic Announcements", bundle: .module)
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.pink)
                
                Spacer()
                
                if #unavailable(macCatalyst 17.0) {
                    content
                } else {
                    content
                        .id(contentId)
                        .onChange(of: scenePhase) { oldPhase, newPhase in
                            if oldPhase == .background {
                                contentId = UUID()
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

#Preview {
    AnnouncementCard()
        .previewPrepared(wrapped: .card)
}
