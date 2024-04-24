import SwiftUI
import ViewUtils
import Utils
import BetterSafariView
import DanXiKit

struct ForumNavigation<Label: View>: View {
    @EnvironmentObject private var navigator: AppNavigator
    let label: () -> Label
    
    var body: some View {
        label()
            .navigationDestination(for: Hole.self) { hole in
                HolePage(hole)
                    .environmentObject(navigator)
            }
            .navigationDestination(for: HoleLoader.self) { loader in
                HoleLoaderPage(loader: loader)
                    .environmentObject(navigator)
            }
            .navigationDestination(for: Tag.self) { tag in
                SearchTagPage(tagName: tag.name)
                    .environmentObject(navigator)
            }
            .navigationDestination(for: ForumSection.self) { section in
                section.destination
                    .environmentObject(navigator)
            }
    }
}

public struct ForumContent: View {
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    @State private var openURL: URL? = nil
    
    func appendContent(value: any Hashable) {
        path.append(value)
    }
    
    func appendDetail(value: any Hashable) {
        path.append(value)
    }
    
    public init() { }
    
    public var body: some View {
        NavigationStack(path: $path) {
            ForumNavigation {
                ForumHomePage()
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

public struct ForumDetail: View {
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    func appendDetail(item: any Hashable, replace: Bool) {
        // FIXME: this code block should exist, but it will cause bug. I'll investigate it later.
        //        if replace {
        //            path.removeLast(path.count)
        //        }
        path.append(item)
    }
    
    public init() { }
    
    public var body: some View {
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
