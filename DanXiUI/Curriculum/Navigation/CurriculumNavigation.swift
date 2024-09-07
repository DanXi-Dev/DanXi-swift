import SwiftUI
import ViewUtils
import Utils
import BetterSafariView
import DanXiKit

struct CurriculumNavigation<Label: View>: View {
    @EnvironmentObject private var navigator: AppNavigator
    let label: () -> Label
    
    var body: some View {
        label()
            .navigationDestination(for: CourseGroup.self) { course in
                CoursePage(courseGroup: course)
            }
            .navigationDestination(for: CurriculumReviewItem.self) { item in
                ReviewPage(course: item.course, review: item.review)
            }
            .navigationDestination(for: CurriculumSection.self) { section in
                switch section {
                case .moderate:
                    CurriculumModeratePage()
                }
            }
    }
}

struct CurriculumReviewItem: Hashable {
    let course: Course
    let review: Review
}


public struct CurriculumContent: View {
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
            CurriculumNavigation {
                CurriculumHomePage()
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
        .onReceive(AppEvents.TabBarTapped.curriculum) { _ in
            if path.isEmpty {
                AppEvents.ScrollToTop.curriculum.send()
            } else {
                path.removeLast(path.count)
            }
        }
    }
}

public struct CurriculumEmbeddedContent: View {
    @EnvironmentObject private var navigator: AppNavigator
    @Binding private var path: NavigationPath
    
    @State private var openURL: URL? = nil
    
    func appendContent(value: any Hashable) {
        path.append(value)
    }
    
    func appendDetail(value: any Hashable) {
        path.append(value)
    }
    
    public init(path: Binding<NavigationPath>) {
        self._path = path
    }
    
    public var body: some View {
        CurriculumNavigation {
            CurriculumHomePage()
        }
        .onReceive(navigator.contentSubject) { value in
            appendContent(value: value)
        }
        .onReceive(navigator.detailSubject) { value, _ in
            if navigator.isCompactMode {
                appendDetail(value: value)
            }
        }
        .onReceive(AppEvents.TabBarTapped.curriculum) { _ in
            if path.isEmpty {
                AppEvents.ScrollToTop.curriculum.send()
            } else {
                path.removeLast(path.count)
            }
        }
    }
}

public struct CurriculumDetail: View {
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    func appendDetail(item: any Hashable, replace: Bool) {
        if replace {
            path.removeLast(path.count)
        }
        path.append(item)
    }
    
    public init() { }
    
    public var body: some View {
        NavigationStack(path: $path) {
            CurriculumNavigation {
                Image(systemName: "books.vertical")
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
