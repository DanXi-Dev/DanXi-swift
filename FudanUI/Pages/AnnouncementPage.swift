import SwiftUI
import ViewUtils
import FudanKit
import SafariServices
import BetterSafariView

struct AnnouncementPage: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject private var campusModel = CampusModel.shared
    @State private var authenticated = false
    @State private var page = 1
    @State private var presentLink: AuthenticatedLink?
    let configuration: SFSafariViewController.Configuration
    
    init() {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        configuration.barCollapsingEnabled = false
        self.configuration = configuration
    }
    
    private func openLink(announcement: Announcement, needAuthenticate: Bool) async {
        func present(url: URL) {
            #if targetEnvironment(macCatalyst)
            openURL(url)
            #else
            presentLink = AuthenticatedLink(url: url)
            #endif
        }
        
        if authenticated || !needAuthenticate {
            present(url: announcement.link)
            return
        }
        
        do {
            let url = try await AuthenticationAPI.authenticateForURL(announcement.link)
            self.authenticated = true
            present(url: url)
        } catch {
            present(url: announcement.link)
        }
    }
    
    var body: some View {
        List {
            AsyncCollection { (previous: [Announcement]) in
                switch(campusModel.studentType) {
                case .undergrad:
                    let announcements = try await UndergraduateAnnouncementStore.shared.getCachedAnnouncements()
                    let previousIds = previous.map(\.id)
                    return announcements.filter({ !previousIds.contains($0.id) })
                default:
                    let announcements = try await PostgraduateAnnouncementStore.shared.getCachedAnnouncements()
                    let previousIds = previous.map(\.id)
                    return announcements.filter({ !previousIds.contains($0.id) })
                }
            } content: { announcement in
                Button {
                    Task {
                        await openLink(announcement: announcement, needAuthenticate: campusModel.studentType == .undergrad)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(announcement.title)
                            Text(announcement.date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                }
            }
#if targetEnvironment(macCatalyst)
            .listRowBackground(Color.clear)
#endif
        }
        .listStyle(.inset)
        .navigationTitle(campusModel.studentType == .undergrad ? String(localized: "Undergraduate Academic Announcements", bundle: .module) : String(localized: "Postgraduate Academic Announcements", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .safariView(item: $presentLink) { link in
            SafariView(url: link.url, configuration: configuration)
        }
    }
}

// Wrap URL inside an Identifiable struct to meet the requirement of BetterSafariView
fileprivate struct AuthenticatedLink: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    NavigationStack {
        AnnouncementPage()
    }
}
