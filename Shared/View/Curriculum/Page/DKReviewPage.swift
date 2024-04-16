import SwiftUI

struct DKReviewPage: View {
    let course: DKCourse
    @State private var review: DKReview
    @EnvironmentObject var model: DKCourseModel
    
    init(course: DKCourse, review: DKReview) {
        self.course = course
        self._review = State(initialValue: review)
    }
    
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
                    
                    Group {
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
                            HStack(alignment: .center, spacing: 3) {
                                Image(systemName: "hand.thumbsup")
                                    .symbolVariant(review.vote == 1 ? .fill : .none)
                            }
                            .foregroundColor(review.vote == 1 ? .pink : .secondary)
                            .fixedSize()
                        }
                        
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
                            HStack(alignment: .center, spacing: 3) {
                                Image(systemName: "hand.thumbsdown")
                                    .symbolVariant(review.vote == -1 ? .fill : .none)
                            }
                            .foregroundColor(review.vote == -1 ? .green : .secondary)
                            .fixedSize()
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    
                    Label("\(String(review.remark))", systemImage: "arrow.up")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                DKRatingView(rank: review.rank)
                
                Text((try? AttributedString(markdown: review.content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                        .inlineOnlyPreservingWhitespace))) ?? AttributedString(review.content))
                
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
