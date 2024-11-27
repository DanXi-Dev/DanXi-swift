import SwiftUI
import BetterSafariView
import Utils
import ViewUtils
import DanXiKit

struct CurriculumHomePage: View {
    @ObservedObject private var model = CurriculumModel.shared
    
    var body: some View {
        AsyncContentView {
            try await model.loadLocal()
            return model.courses
        } refreshAction: {
            try await model.loadRemote()
            return model.courses
        } content: { courses in
            HomePageContent(courses: courses)
                .id("DKHomePageContent-View")
        }
        .navigationTitle(String(localized: "Curriculum Board", bundle: .module))
    }
}

fileprivate struct HomePageContent: View {
    @ObservedObject private var profileStore = ProfileStore.shared
    let courses: [CourseGroup]
    @State private var searchText = ""
    
    private var searchResults: [CourseGroup] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.code.localizedCaseInsensitiveContains(searchText) || $0.teachers.contains(where: { $0.localizedCaseInsensitiveContains(searchText)})}
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                EmptyView()
                    .id("dk-top")
                
                ForEach(searchResults) { course in
                    DetailLink(value: course) {
                        CourseView(courseGroup: course)
                            .navigationStyle()
                    }
                }
            }
            .onReceive(AppEvents.ScrollToTop.curriculum) {
                withAnimation {
                    proxy.scrollTo("dk-top")
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText)
        .toolbar {
            if profileStore.isAdmin {
                Menu {
                    DetailLink(value: CurriculumSection.moderate) {
                        Label(String(localized: "Admin Actions", bundle: .module), systemImage: "person.badge.key")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
