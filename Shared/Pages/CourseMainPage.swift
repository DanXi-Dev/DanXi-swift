import SwiftUI

struct CourseMainPage: View {
    @AppStorage("course-hash") var courseHash = ""
    @State var courses: [DKCourseGroup]
    
    @State var searchText = ""
    
    @State var loading = true
    @State var initFinished = false
    @State var errorInfo = ""
    
    
    init() {
        self._courses = State(initialValue: [])
    }
    
    init(courses: [DKCourseGroup]) { // preview purpose
        self._courses = State(initialValue: courses)
        self._initFinished = State(initialValue: true)
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
            newHash = try await DXNetworks.shared.loadCourseHash()
            if newHash == courseHash { // no change from last fetch, use local storage
                initFinished = true
                return
            }
        } catch {
            
        }
        
        do { // make network call
            courses = try await DXNetworks.shared.loadCourseGroups()
            saveDKCourseList(courses)
            courseHash = newHash // defer update course hash to prevent hash-content inconsistent
            initFinished = true
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    var body: some View {
        LoadingView(loading: $loading,
                        finished: $initFinished,
                        errorDescription: errorInfo,
                        action: initialLoad) {
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
