import SwiftUI
import SafariServices

struct FDNoticePage: View {
    @State private var authenticated = false
    @State private var page = 1
    @State private var notice: FDNotice?
    
    private func loadNotice() async throws -> [FDNotice] {
        let notices = try await FDNoticeAPI.getNoticeList(page)
        page += 1
        return notices
    }
    
    var body: some View {
        List {
            AsyncCollection { _ in
                return try await loadNotice()
            } content: { notice in
                Button {
                    self.notice = notice
                } label: {
                    NoticeView(notice: notice)
                }
            }
        }
        .navigationTitle("Academic Office Announcements")
        .sheet(item: $notice) { notice in
            AsyncContentView { () -> URL in
                if authenticated {
                    return notice.link
                }
                
                do {
                    let url = try await FDNoticeAPI.authenticate(notice.link)
                    authenticated = true
                    return url
                } catch {
                    return notice.link
                }
            } content: { url in
                SafariView(url: url)
                    .ignoresSafeArea()
            }
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

fileprivate struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        configuration.barCollapsingEnabled = false
        let controller = SFSafariViewController(url: url, configuration: configuration)
        return controller
    }
    
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {
        
    }
}
