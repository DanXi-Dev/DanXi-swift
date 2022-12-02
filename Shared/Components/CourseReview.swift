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
                
                Label("\(String(review.vote))", systemImage: "arrow.up")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Text(review.content)
                .multilineTextAlignment(.leading)
                .lineLimit(10)

            HStack {
                Text(course.teachers)
                    .tagStyle(color: .accentColor)
                Text(course.formattedSemester)
                    .tagStyle(color: .accentColor)
                Spacer()
                Text(review.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(7.0)
        .padding(.vertical, 3)
    }
}

struct CourseReview_Previews: PreviewProvider {
    static let courseGroup: DKCourseGroup = Bundle.main.decodeData("course")
    
    static var previews: some View {
        CourseReview(review: Bundle.main.decodeData("review"), course: courseGroup.courses.first!)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
