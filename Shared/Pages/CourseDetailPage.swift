import SwiftUI

struct CourseDetailPage: View {
    let course: DKCourseGroup
    
    var body: some View {
        Text(course.code)
            .navigationTitle(course.name)
    }
}

struct CourseDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CourseDetailPage(course: PreviewDecode.decodeObj(name: "course")!)
        }
    }
}
