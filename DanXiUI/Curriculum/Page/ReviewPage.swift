import MarkdownUI
import SwiftUI
import ViewUtils
import DanXiKit

struct ReviewPage: View {
    let course: Course
    @State private var review: Review
    @EnvironmentObject var model: CourseModel
    
    init(course: Course, review: Review) {
        self.course = course
        self._review = State(initialValue: review)
    }
    
    @ViewBuilder private var likeButtons: some View {
        AsyncButton {
            try await withHaptics {
                let upvote = review.vote >= 0
                self.review = try await CurriculumAPI.voteReview(id: review.id, upvote: upvote)
                model.updateReview(self.review, forCourseId: course.id)
            }
        } label: {
            Image(systemName: "arrow.up")
                .padding(.horizontal)
                .foregroundColor(.primary)
        }
        .buttonStyle(.borderedProminent)
        .tint(review.vote == 1 ? .accentColor : .secondarySystemBackground)
        
        AsyncButton {
            try await withHaptics {
                let upvote = review.vote <= 0
                self.review = try await CurriculumAPI.voteReview(id: review.id, upvote: !upvote)
                model.updateReview(self.review, forCourseId: course.id)
            }
        } label: {
            Image(systemName: "arrow.down")
                .padding(.horizontal)
                .foregroundColor(.primary)
        }
        .buttonStyle(.borderedProminent)
        .tint(review.vote == -1 ? .accentColor : .secondarySystemBackground)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(review.title)
                    .font(.title)
                    .bold()
                HStack {
                    CourseTagView {
                        Text(course.teachers)
                    }
                    CourseTagView {
                        Text(course.formattedSemester)
                    }
                    Spacer()
                    
                    Label(String(review.remark), systemImage: "arrow.up")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                RatingView(rank: review.rank)
                    .padding(.bottom, 6)
                
                Text((try? AttributedString(markdown: review.content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                    .inlineOnlyPreservingWhitespace))) ?? AttributedString(review.content))
                .font(.body.leading(.loose))
                
                HStack {
                    likeButtons
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Posted by: \(String(review.reviewerId))", bundle: .module)
                        Text(review.timeUpdated.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
            }
        }
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline) // this is to remove the top padding
    }
}
