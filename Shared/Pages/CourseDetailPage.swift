import SwiftUI

struct CourseDetailPage: View {
    @State var courseGroup: DKCourseGroup
    @State var showCourseInfo = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(courseGroup.code)
                    .foregroundColor(.secondary)
                Divider()
                courseInfo
                
                Divider()
                Text("Course Review")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                courseReview
            }
            .padding(.horizontal)
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading
            ) 
        }
        .navigationTitle(courseGroup.name)
    }
    
    private var courseInfo: some View {
        DisclosureGroup(isExpanded: $showCourseInfo) {
            VStack(alignment: .leading) {
                Label("Professors", systemImage: "person.fill")
                Text(courseGroup.courses.map { $0.teachers }.formatted())
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Credit", systemImage: "a.square.fill")
                Text("\(String(courseGroup.courses.first!.credit)) Credit")
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Campus", systemImage: "building.fill")
                Text(courseGroup.campus)
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Department", systemImage: "building.columns.fill")
                Text(courseGroup.department)
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
            .font(.callout)
            .padding(.top, 15)
        } label: {
            Text("Course Information")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    
    
    private var courseReview: some View {
        ForEach(courseGroup.courses) { course in
            ForEach(course.reviews) { review in
                CourseReview(review: review, course: course)
            }
        }
    }
}

struct CourseDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                CourseDetailPage(courseGroup: PreviewDecode.decodeObj(name: "course")!)
            }
            NavigationView {
                CourseDetailPage(courseGroup: PreviewDecode.decodeObj(name: "course")!)
            }
            .preferredColorScheme(.dark)
        }
    }
}
