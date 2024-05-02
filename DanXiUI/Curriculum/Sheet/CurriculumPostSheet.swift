import SwiftUI
import ViewUtils
import DanXiKit

struct CurriculumPostSheet: View {
    let courseGroup: CourseGroup
    
    @State private var courseId: Int = -1
    
    @State private var overallRating = 0
    @State private var contentRating = 0
    @State private var workloadRating = 0
    @State private var assessmentRating = 0
    
    @State private var title = ""
    @State private var content = ""

    private var allowSubmit: Bool {
        courseId != -1 &&
        !title.isEmpty && !content.isEmpty &&
        overallRating != 0 && contentRating != 0 && workloadRating != 0 && assessmentRating != 0
    }
    
    private var allowDiscard: Bool {
        courseId != -1 ||
        !title.isEmpty || !content.isEmpty ||
        overallRating != 0 || contentRating != 0 || workloadRating != 0 || assessmentRating != 0
    }
    
    var body: some View {
        Sheet("New Review") {
            let rank = Rank(overall: Double(overallRating), content: Double(contentRating), workload: Double(workloadRating), assessment: Double(assessmentRating))
            _ = try await CurriculumAPI.createReview(courseId: courseId, title: content, content: title, rank: rank)
        } content: {
            Section {
                Picker("Select Course", selection: $courseId) {
                    Text("Not Selected")
                        .tag(-1)
                    
                    ForEach(courseGroup.courses) { course in
                        Text("\(course.formattedSemester) \(course.teachers)")
                            .tag(course.id)
                    }
                }
            }
            
            Section {
                TextField("Review Title", text: $title)
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Enter review content")
                            .foregroundColor(.primary.opacity(0.25))
                            .padding(.top, 7)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $content)
                        .frame(height: 250)
                }
            }
            
            Section {
                LabeledContent("Overall Rating") {
                    StarRatingView(rating: $overallRating, ratingType: .overall)
                }
                LabeledContent("Course Content") {
                    StarRatingView(rating: $contentRating, ratingType: .content)
                }
                LabeledContent("Course Workload") {
                    StarRatingView(rating: $workloadRating, ratingType: .workload)
                }
                LabeledContent("Course Assessment") {
                    StarRatingView(rating: $assessmentRating, ratingType: .assessment)
                }
            } header: {
                Text("Course Evaluation")
            }
        }
        .completed(allowSubmit)
        .warnDiscard(allowDiscard)
        .scrollDismissesKeyboard(.immediately)
    }
}
