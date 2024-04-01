import SwiftUI

struct DKReviewPage: View {
    let course: DKCourse
    let review: DKReview
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(review.title)
                    .font(.title)
                    .bold()
                HStack {
                    DKTagView {
                        Text(course.teachers)
                    }
                    DKTagView {
                        Text(course.formattedSemester)
                    }
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
        .watermark()
        .navigationBarTitleDisplayMode(.inline) // this is to remove the top padding
        /*
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
         */
    }
}
