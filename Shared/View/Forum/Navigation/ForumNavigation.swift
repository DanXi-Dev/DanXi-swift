import SwiftUI
import ViewUtils
import Utils
import BetterSafariView

struct ForumNavigation<Label: View>: View {
    @EnvironmentObject private var navigator: AppNavigator
    let label: () -> Label
    
    var body: some View {
        label()
            .navigationDestination(for: THHole.self) { hole in
                THHolePage(hole)
                    .environmentObject(navigator)
            }
            .navigationDestination(for: THHoleLoader.self) { loader in
                THLoaderPage(loader)
                    .environmentObject(navigator)
            }
            .navigationDestination(for: THTag.self) { tag in
                THSearchTagPage(tagname: tag.name)
                    .environmentObject(navigator)
            }
            .navigationDestination(for: ForumSection.self) { section in
                section.destination
                    .environmentObject(navigator)
            }
    }
}

struct ForumContent: View {
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    @State private var openURL: URL? = nil
    
    func appendContent(value: any Hashable) {
        path.append(value)
    }
    
    func appendDetail(value: any Hashable) {
        path.append(value)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ForumNavigation {
                THHomePage()
            }
        }
        .onReceive(navigator.contentSubject) { value in
            appendContent(value: value)
        }
        .onReceive(navigator.detailSubject) { value, _ in
            if navigator.isCompactMode {
                appendDetail(value: value)
            }
        }
        .onReceive(AppEvents.TabBarTapped.forum) { _ in
            if path.isEmpty {
                AppEvents.ScrollToTop.forum.send()
            } else {
                path.removeLast(path.count)
            }
        }
#if !targetEnvironment(macCatalyst)
        .environment(\.openURL, OpenURLAction { url in
            openURL = url
            return .handled
        })
        .safariView(item: $openURL) { link in
            SafariView(url: link)
        }
#endif
    }
}

struct ForumDetail: View {
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    func appendDetail(item: any Hashable, replace: Bool) {
        // FIXME: this code block should exist, but it will cause bug. I'll investigate it later.
        //        if replace {
        //            path.removeLast(path.count)
        //        }
        path.append(item)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ForumNavigation {
                Image(systemName: "text.bubble")
                    .symbolVariant(.fill)
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 60))
            }
        }
        .onReceive(navigator.detailSubject) { item, replace in
            appendDetail(item: item, replace: replace)
        }
    }
}