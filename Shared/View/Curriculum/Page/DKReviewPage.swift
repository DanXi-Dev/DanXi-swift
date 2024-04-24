import MarkdownUI
import SwiftUI

struct DKReviewPage: View {
    let course: DKCourse
    @State private var review: DKReview
    @EnvironmentObject var model: DKCourseModel
    
    init(course: DKCourse, review: DKReview) {
        self.course = course
        self._review = State(initialValue: review)
    }
    
    @ViewBuilder private var likeButtons: some View {
        AsyncButton {
            prepareHaptic()
            do {
                let upvote = review.vote >= 0
                self.review = try await DKRequests.voteReview(reviewId: review.id, upvote: upvote)
                model.updateReview(self.review, forCourseId: course.id)
                haptic(.success)
            } catch {
                haptic(.error)
            }
        } label: {
            Image(systemName: "arrow.up")
                .padding(.horizontal)
                .foregroundColor(.primary)
        }
        .buttonStyle(.borderedProminent)
        .tint(review.vote == 1 ? .accentColor : .secondarySystemBackground)
        
        AsyncButton {
            prepareHaptic()
            do {
                let upvote = review.vote <= 0
                self.review = try await DKRequests.voteReview(reviewId: review.id, upvote: !upvote)
                model.updateReview(self.review, forCourseId: course.id)
                haptic(.success)
            } catch {
                haptic(.error)
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
                    .font(.title2)
                    .bold()
                HStack {
                    DKTagView {
                        Text(course.teachers)
                    }
                    DKTagView {
                        Text(course.formattedSemester)
                    }
                    Spacer()
                    
                    Label("\(String(review.remark))", systemImage: "arrow.up")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                DKRatingView(rank: review.rank)
                
                Text((try? AttributedString(markdown: review.content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                    .inlineOnlyPreservingWhitespace))) ?? AttributedString(review.content))
                    .relativeLineSpacing(.em(0.18))
                
                HStack {
                    likeButtons
                    
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
    }
}
