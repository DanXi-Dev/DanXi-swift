import SwiftUI

struct CourseMainPage: View {
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
        var newHash = courseHash
        
        do { // check hash, try decode from local storage
            courses = loadDKCourseList()
            newHash = try await NetworkRequests.shared.loadCourseHash()
            if newHash == courseHash { // no change from last fetch, use local storage
                return
            }
        } catch {
            print("DANXI-DEBUG: check local storage failed")
        }
        
        do { // make network call
            courses = try await NetworkRequests.shared.loadCourseGroups()
            saveDKCourseList(courses)
            courseHash = newHash // defer update course hash to prevent loading course fail
        } catch {
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
