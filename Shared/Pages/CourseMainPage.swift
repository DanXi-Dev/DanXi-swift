import SwiftUI

struct CourseMainPage: View {
    @AppStorage("course-data") var courseData = Data() // cache data
    @AppStorage("course-hash") var courseHash = ""
    @State var courses: [DKCourseGroup] = []
    
    func initialLoad() async {
        print("DANXI-DEBUG: course hash \(courseHash)")
        
        do { // check hash, try decode from local storage
            let newHash = try await networks.loadCourseHash()
            if newHash == courseHash { // no change from last fetch, use local storage
                print("DANXI-DEBUG: using local storage")
                courses = try JSONDecoder().decode([DKCourseGroup].self, from: courseData)
                return
            } else {
                courseHash = newHash // changed
            }
        } catch {
            print("DANXI-DEBUG: check local storage failed")
        }
        
        do {
            (courses, courseData) = try await networks.loadCourseGroups()
            print("DANXI-DEBUG: making network call")
        } catch {
            print(error)
            print("DANXI-DEBUG: initial load failed")
        }
    }
    
    var body: some View {
        List {
            ForEach(courses) { course in
                CourseView(courseGroup: course)
            }
        }
        .navigationTitle("Curriculum Board")
        .listStyle(.grouped)
        .task {
            await initialLoad()
        }
        
    }
}

struct CourseMainPage_Previews: PreviewProvider {
    static var previews: some View {
        CourseMainPage()
    }
}
