import SwiftUI
import BetterSafariView
import Utils
import ViewUtils

struct DKHomePage: View {
    @ObservedObject private var model = DKModel.shared
    
    @State private var showErrorAlert = false
    @State private var errorAlertContent = ""
    
    var body: some View {
        if model.courses.isEmpty {
            ProgressView()
                .task {
                    await model.loadLocal()
                }
        } else {
            HomePageContent(courses: model.courses)
                .task(priority: .background) {
                    try? await model.loadRemote()
                }
                .refreshable {
                    do {
                        try await model.loadRemote()
                    } catch {
                        errorAlertContent = error.localizedDescription
                        showErrorAlert = true
                    }
                }
                .alert("Error", isPresented: $showErrorAlert) {} message: {
                    Text(errorAlertContent)
                }
        }
    }
}

fileprivate struct HomePageContent: View {
    let courses: [DKCourseGroup]
    @State private var searchText = ""
    @State private var openURL: URL? = nil
    @StateObject var navigator = DKNavigator()
    
    private var searchResults: [DKCourseGroup] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.code.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
            ScrollViewReader { proxy in
                List {
                    EmptyView()
                        .id("dk-top")
                    
                    ForEach(searchResults) { course in
                        DetailLink(value: course) {
                            DKCourseView(courseGroup: course)
                                .navigationStyle()
                        }
                    }
                }
                .onReceive(OnDoubleTapCurriculumTabBarItem) {
                    if navigator.path.count > 0 {
                        navigator.path.removeLast(navigator.path.count)
                    } else {
                        withAnimation {
                            proxy.scrollTo("dk-top")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
            .navigationTitle("Curriculum Board")
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

class DKNavigator: ObservableObject {
    @Published var path = NavigationPath()
}
