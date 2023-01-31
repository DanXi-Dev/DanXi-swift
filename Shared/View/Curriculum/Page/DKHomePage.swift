import SwiftUI

struct DKHomePage: View {
    @ObservedObject var courseStore = DKStore.shared
    @State var searchText = ""
    
    @State var loading = true
    @State var initFinished = false
    @State var errorInfo = ""
    
    
    init() { }
    
    init(courses: [DKCourseGroup]) { // preview purpose
        DKStore.shared.courses = courses
        DKStore.shared.initialized = true
    }
    
    
    var searchResults: [DKCourseGroup] {
        if searchText.isEmpty {
            return courseStore.courses
        } else {
            // TODO: search course ID
            return courseStore.courses.filter { $0.name.contains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            LoadingPage(finished: courseStore.initialized) {
                // FIXME: DKStore cannot create file in filesystem
                courseStore.courses = try await DKRequests.loadCourseGroups()
                courseStore.initialized = true
            } content: {
                List {
                    ForEach(searchResults) { course in
                        NavigationLink(value: course) {
                            DKCourseView(courseGroup: course)
                        }
                    }
                }
                .searchable(text: $searchText)
                .navigationTitle("Curriculum Board")
                .navigationDestination(for: DKCourseGroup.self) { course in
                    DKCoursePage(courseGroup: course)
                }
            }
        }
    }
}

struct DKHomePage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DKHomePage(courses: Bundle.main.decodeData("course-list"))
        }
    }
}
