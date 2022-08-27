import SwiftUI

struct CourseDetailPage: View {
    let course: DKCourseGroup
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(course.code)
                .foregroundColor(.secondary)
            Divider()
            CourseInfo(course: course)
            
            Divider()
            Text("Course Review")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            CourseReview(course: course)
        }
        .padding(.horizontal)
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .navigationTitle(course.name)
    }
}


struct CourseInfo: View {
    @State var showCourseInfo = true
    let course: DKCourseGroup
    let professors: [String]
    
    init(course: DKCourseGroup) {
        self.course = course
        self.professors = course.courses.map { $0.teachers }
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $showCourseInfo) {
            VStack(alignment: .leading) {
                Label("Professors", systemImage: "person.fill")
                Text(professors.formatted())
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Credit", systemImage: "a.square.fill")
                Text("\(String(course.courses.first!.credit)) Credit")
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Campus", systemImage: "building.fill")
                Text(course.campus)
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Department", systemImage: "building.columns.fill")
                Text(course.department)
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
            }
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .padding(.top, 15)
        } label: {
            Text("Course Information")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}

struct CourseReview: View {
    let course: DKCourseGroup
    
    var body: some View {
        List {
            Text("Placeholder") // TODO: course review section
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}

struct CourseDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CourseDetailPage(course: PreviewDecode.decodeObj(name: "course")!)
        }
    }
}


