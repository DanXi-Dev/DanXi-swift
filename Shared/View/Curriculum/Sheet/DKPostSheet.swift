import SwiftUI

struct DKPostSheet: View {
    let courseGroup: DKCourseGroup
    
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
    
    var body: some View {
        Sheet("New Review") {
            let rank = DKRank(overall: Double(overallRating),
                              content: Double(contentRating),
                              workload: Double(workloadRating),
                              assessment: Double(assessmentRating))
            _ = try await DKRequests.postReview(courseId: courseId,
                                                content: content,
                                                title: title,
                                                rank: rank)
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
            
            if !content.isEmpty {
                Section {
                    MarkdownView(content)
                } header: {
                    Text("Preview")
                }
            }
            
            Section {
                LabeledContent("Overall Rating") {
                    DKStarRatingView(rating: $overallRating, ratingType: .overall)
                }
                LabeledContent("Course Content") {
                    DKStarRatingView(rating: $contentRating, ratingType: .content)
                }
                LabeledContent("Course Workload") {
                    DKStarRatingView(rating: $workloadRating, ratingType: .workload)
                }
                LabeledContent("Course Assessment") {
                    DKStarRatingView(rating: $assessmentRating, ratingType: .assessment)
                }
            } header: {
                Text("Course Evaluation")
            }
        }
        .completed(allowSubmit)
        .warnDiscard()
        .scrollDismissesKeyboard(.immediately)
    }
}

struct DKPostSheet_Previews: PreviewProvider {
    static var previews: some View {
        DKPostSheet(courseGroup: Bundle.main.decodeData("course")!)
    }
}
