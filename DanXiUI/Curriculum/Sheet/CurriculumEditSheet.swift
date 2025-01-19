import SwiftUI
import ViewUtils
import DanXiKit

struct CurriculumEditSheet: View {
    private let reviewId: Int
    @Binding var review: Review
    
    @State private var overallRating: Int
    @State private var contentRating: Int
    @State private var workloadRating: Int
    @State private var assessmentRating: Int
    
    @State private var title: String
    @State private var content: String

    private var allowSubmit: Bool {
        !title.isEmpty && !content.isEmpty &&
        overallRating != 0 && contentRating != 0 && workloadRating != 0 && assessmentRating != 0
    }
    
    private var allowDiscard: Bool {
        !title.isEmpty || !content.isEmpty ||
        overallRating != 0 || contentRating != 0 || workloadRating != 0 || assessmentRating != 0
    }
    
    init(courseGroup: CourseGroup, course: Course, review: Binding<Review>) {
        self._review = review
        let reviewValue = review.wrappedValue
        self.reviewId = reviewValue.id
        self.overallRating = Int(reviewValue.rank.overall)
        self.contentRating = Int(reviewValue.rank.content)
        self.workloadRating = Int(reviewValue.rank.workload)
        self.assessmentRating = Int(reviewValue.rank.assessment)
        self.title = reviewValue.title
        self.content = reviewValue.content
    }
    
    var body: some View {
        Sheet(String(localized: "Edit Review", bundle: .module)) {
            let rank = Rank(overall: Double(overallRating), content: Double(contentRating), workload: Double(workloadRating), assessment: Double(assessmentRating))
            review = try await CurriculumAPI.modifyReview(reviewId: reviewId, title: title, content: content, rank: rank)
        } content: {
            Section {
                TextField(String(localized: "Review Title", bundle: .module), text: $title)
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Enter review content", bundle: .module)
                            .foregroundColor(.primary.opacity(0.25))
                            .padding(.top, 7)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $content)
                        .frame(height: 250)
                }
            }
            
            Section {
                LabeledContent {
                    StarRatingView(rating: $overallRating, ratingType: .overall)
                } label: {
                    Text("Overall Rating", bundle: .module)
                }
                
                LabeledContent {
                    StarRatingView(rating: $contentRating, ratingType: .content)
                } label: {
                    Text("Course Content", bundle: .module)
                }
                
                LabeledContent {
                    StarRatingView(rating: $workloadRating, ratingType: .workload)
                } label: {
                    Text("Course Workload", bundle: .module)
                }
                
                LabeledContent {
                    StarRatingView(rating: $assessmentRating, ratingType: .assessment)
                } label: {
                    Text("Course Assessment", bundle: .module)
                }
            } header: {
                Text("Course Evaluation", bundle: .module)
            }
        }
        .completed(allowSubmit)
        .warnDiscard(allowDiscard)
        .scrollDismissesKeyboard(.immediately)
    }
}
