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
                        Text(review.timeUpdated.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
                
                
                let medals : [String] = Array(Set(review.extra.achievements.map{ $0.name }))
                var medalGroups : [[String]] {
                    stride(from: 0, to: medals.count, by: 3).map { index in
                        Array(medals[index..<min(index + 3, medals.count)])
                    }
                }
                
                
                VStack (alignment: .trailing){
                    ForEach (medalGroups, id: \.self) { group in
                        HStack {
                            ForEach(group, id: \.self) { medal in
                                Image(medal, bundle: .module)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height : 35)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

            }
        }
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline) // this is to remove the top padding
    }
}
