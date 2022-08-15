import SwiftUI

struct CourseMainPage: View {
    @AppStorage("course-data") var courseData = Data() // cache data
    @AppStorage("course-hash") var courseHash = ""
    @State var courses: [DKCourseGroup]
    
    init() {
        self._courses = State(initialValue: [])
    }
    
    init(courses: [DKCourseGroup]) {
        self._courses = State(initialValue: courses)
    }
    
    @State var searchText = ""
    var searchResults: [DKCourseGroup] {
        if searchText.isEmpty {
            return courses
        } else {
            // TODO: search course ID
            return courses.filter { $0.name.contains(searchText) }
        }
    }
    
    func initialLoad() async {        
        do { // check hash, try decode from local storage
            let newHash = try await NetworkRequests.shared.loadCourseHash()
            if newHash == courseHash { // no change from last fetch, use local storage
                courses = try JSONDecoder().decode([DKCourseGroup].self, from: courseData)
                return
            } else {
                courseHash = newHash // changed
            }
        } catch {
            print("DANXI-DEBUG: check local storage failed")
        }
        
        do { // make network call
            (courses, courseData) = try await NetworkRequests.shared.loadCourseGroups()
        } catch {
            print(error)
            print("DANXI-DEBUG: initial load failed")
        }
    }
    
    var body: some View {
        List {
            ForEach(searchResults) { course in
                CourseView(courseGroup: course)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Curriculum Board")
        .listStyle(.grouped)
        .task {
            await initialLoad()
        }
        
    }
}

struct CourseMainPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CourseMainPage(courses: PreviewDecode.decodeList(name: "course-list"))
        }
    }
}
