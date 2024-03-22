import SwiftUI
import SafariServices
import BetterSafariView

struct FDNoticePage: View {
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
    
    private func loadNotice() async throws -> [FDNotice] {
        let notices = try await FDNoticeAPI.getNoticeList(page)
        page += 1
        return notices
    }
    
    private func authenticateLink(notice: FDNotice) async {
        if authenticated {
            presentLink = AuthenticatedLink(url: notice.link)
            return
        }
        
        do {
            let url = try await FDNoticeAPI.authenticate(notice.link)
            self.authenticated = true
            presentLink = AuthenticatedLink(url: url)
        } catch {
            presentLink = AuthenticatedLink(url: notice.link)
        }
    }
    
    var body: some View {
        List {
            AsyncCollection { _ in
                return try await loadNotice()
            } content: { notice in
                Button {
                    Task {
                        await authenticateLink(notice: notice)
                    }
                } label: {
                    NoticeView(notice: notice)
                }
            }
        }
        .navigationTitle("Academic Office Announcements")
        .navigationBarTitleDisplayMode(.inline)
        .safariView(item: $presentLink) { link in
            SafariView(url: link.url, configuration: configuration)
        }
    }
}

fileprivate struct NoticeView: View {
    let notice: FDNotice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text(notice.title)
                Text(notice.date)
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

// Wrap URL inside an Identifiable struct to meet the requirement of BetterSafariView
fileprivate struct AuthenticatedLink: Identifiable {
    let id = UUID()
    let url: URL
}
