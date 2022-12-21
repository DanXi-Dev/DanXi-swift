import SwiftUI

struct DKReviewPage: View {
    let course: DKCourse
    let review: DKReview
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Text(course.teachers)
                        .tagStyle(color: .accentColor)
                    Text(course.formattedSemester)
                        .tagStyle(color: .accentColor)
                    Spacer()
                    Label("\(String(review.vote))", systemImage: "arrow.up")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                DKRatingView(rank: review.rank)
                
                Text(review.content)
                
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Posted by: \(String(review.reviewerId))")
                        Text(review.updateTime.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
            }
        }
        .padding(.horizontal)
        .navigationTitle(review.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    // TODO: upvote
                } label: {
                    Image(systemName: "arrowtriangle.up")
                }
                
                Button {
                    // TODO: downvote
                } label: {
                    Image(systemName: "arrowtriangle.down")
                }
            }
        }
    }
}

struct ReviewPage_Previews: PreviewProvider {
    static let courseGroup: DKCourseGroup = Bundle.main.decodeData("course")
    
    static var previews: some View {
        NavigationView {
            DKReviewPage(course: courseGroup.courses.first!, review: Bundle.main.decodeData("review")!)
        }
    }
}
