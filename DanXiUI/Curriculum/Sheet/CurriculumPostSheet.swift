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
        Sheet(String(localized: "New Review", bundle: .module)) {
            let rank = Rank(overall: Double(overallRating), content: Double(contentRating), workload: Double(workloadRating), assessment: Double(assessmentRating))
            _ = try await CurriculumAPI.createReview(courseId: courseId, title: title, content: content, rank: rank)
        } content: {
            Section {
                Picker(selection: $courseId) {
                    Text("Not Selected", bundle: .module)
                        .tag(-1)
                    
                    ForEach(courseGroup.courses) { course in
                        Text("\(course.formattedSemester) \(course.teachers)", bundle: .module)
                            .tag(course.id)
                    }
                } label: {
                    Text("Select Course", bundle: .module)
                }
            }
            
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
