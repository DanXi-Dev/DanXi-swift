import SwiftUI

struct CourseMainPage: View {
    @State var courses: [DKCourseGroup] = []
    
    func loadCourse() async {
        do {
            courses = try await networks.loadCourseGroups()
        } catch {
            print("DANXI-DEBUG: load course group failed")
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
            await loadCourse()
        }
        
    }
}

struct CourseMainPage_Previews: PreviewProvider {
    static var previews: some View {
        CourseMainPage()
    }
}
