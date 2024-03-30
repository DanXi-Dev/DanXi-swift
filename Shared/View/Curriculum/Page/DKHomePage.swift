import SwiftUI

struct DKHomePage: View {
    @ObservedObject private var appModel = DXModel.shared
    
    var body: some View {
        var userId: String {
            appModel.user?.id != nil ? String(appModel.user!.id) : ""
        }
        
        AsyncContentView { () -> [DKCourseGroup] in
            try await DKModel.shared.loadAll()
            return DKModel.shared.courses
        } content: { courses in
            HomePageContent(courses: courses)
                .watermark(content: userId, opacity: THSettings.shared.watermarkOpacity)
        }
    }
}

fileprivate struct HomePageContent: View {
    let courses: [DKCourseGroup]
    @State private var searchText = ""
    
    private var searchResults: [DKCourseGroup] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.code.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(searchResults) { course in
                    NavigationLink(value: course) {
                        DKCourseView(courseGroup: course)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
            .navigationTitle("Curriculum Board")
            .navigationDestination(for: DKCourseGroup.self) { course in
                DKCoursePage(courseGroup: course)
            }
        }
    }
}
