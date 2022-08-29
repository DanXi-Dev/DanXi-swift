import SwiftUI

struct CourseMainPage: View {
    @AppStorage("course-hash") var courseHash = ""
    @State var courses: [DKCourseGroup]
    
    @State var searchText = ""
    
    @State var loading = true
    @State var failed = false
    @State var errorInfo = ErrorInfo()
    
    
    init() {
        self._courses = State(initialValue: [])
    }
    
    init(courses: [DKCourseGroup]) { // preview purpose
        self._courses = State(initialValue: courses)
        self._loading = State(initialValue: false)
    }
    
    
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
            
        }
        
        do { // make network call
            courses = try await NetworkRequests.shared.loadCourseGroups()
            saveDKCourseList(courses)
            courseHash = newHash // defer update course hash to prevent hash-content inconsistent
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            failed = true
            errorInfo = error.localizedErrorDescription
        } catch {
            failed = true
            errorInfo = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        InitLoadingView(loading: $loading,
                        failed: $failed,
                        errorDescription: errorInfo.description) {
            await initialLoad()
        } content: {
            List {
                ForEach(searchResults) { course in
                    NavigationLink(destination: CourseDetailPage(courseGroup: course)) {
                        CourseView(courseGroup: course)
                    }
                }
            }
            .searchable(text: $searchText)
            .listStyle(.grouped)
            .navigationTitle("Curriculum Board")
        }
    }
}

struct CourseMainPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                CourseMainPage(courses: PreviewDecode.decodeList(name: "course-list"))
            }
            
            NavigationView {
                CourseMainPage(courses: PreviewDecode.decodeList(name: "course-list"))
            }
            .preferredColorScheme(.dark)
        }
    }
}
