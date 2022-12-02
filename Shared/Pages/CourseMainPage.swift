import SwiftUI

struct CourseMainPage: View {
    @ObservedObject var courseStore = CourseStore.shared
    @State var searchText = ""
    
    @State var loading = true
    @State var initFinished = false
    @State var errorInfo = ""
    
    
    init() { }
    
    init(courses: [DKCourseGroup]) { // preview purpose
        CourseStore.shared.courses = courses
        CourseStore.shared.initialized = true
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
        LoadingView(finished: courseStore.initialized) {
            try await courseStore.loadCourses()
        } content: {
            List {
                ForEach(searchResults) { course in
                    NavigationLink(value: course) {
                        CourseView(courseGroup: course)
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Curriculum Board")
            .navigationDestination(for: DKCourseGroup.self) { course in
                CourseDetailPage(courseGroup: course)
            }
        }
    }
}

struct CourseMainPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CourseMainPage(courses: Bundle.main.decodeData("course-list"))
        }
    }
}
