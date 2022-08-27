import SwiftUI

struct CourseReview: View {
    let review: DKReview
    let course: DKCourse
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(review.title)
                        .font(.headline)
                        .lineLimit(1)
                    StarsView(rating: CGFloat(review.rank.overall))
                        .frame(width: 60)
                        .offset(x: 0, y: -6)
                }

                Spacer()
            }

            Text(review.content)
                .lineLimit(10)

            HStack {
                Text(course.teachers)
                    .tagStyle(color: .accentColor)
                Text("\(String(course.year)) - \(course.semester)") // TODO: format semester style
                    .tagStyle(color: .accentColor)
                Spacer()
                Text(review.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(7.0)
        .padding(.vertical, 3)
    }
}

struct CourseReview_Previews: PreviewProvider {
    static let courseGroup: DKCourseGroup = PreviewDecode.decodeObj(name: "course")!
    
    static var previews: some View {
        CourseReview(review: PreviewDecode.decodeObj(name: "review")!, course: courseGroup.courses.first!)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
