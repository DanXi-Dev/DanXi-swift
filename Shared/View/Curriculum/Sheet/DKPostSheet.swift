import SwiftUI

struct DKPostSheet: View {
    let courseGroup: DKCourseGroup
    
    @State var courseId: Int = -1
    
    @State var overallRating = 0
    @State var contentRating = 0
    @State var workloadRating = 0
    @State var assessmentRating = 0
    
    @State var title = ""
    @State var content = ""

    var allowSubmit: Bool {
        courseId != -1 &&
        !title.isEmpty && !content.isEmpty &&
        overallRating != 0 && contentRating != 0 && workloadRating != 0 && assessmentRating != 0
    }
    
    var body: some View {
        FormPrimitive(title: "New Review",
                      allowSubmit: allowSubmit,
                      errorTitle: "Send Review Failed") {
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
                TextEditView($content,
                             placeholder: "Enter review content")
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
                    DKStarRatingView(rating: $overallRating)
                }
                LabeledContent("Course Content") {
                    DKStarRatingView(rating: $contentRating)
                }
                LabeledContent("Course Workload") {
                    DKStarRatingView(rating: $workloadRating)
                }
                LabeledContent("Course Assessment") {
                    DKStarRatingView(rating: $assessmentRating)
                }
            } header: {
                Text("Course Evaluation")
            }
        } action: {
            let rank = DKRank(overall: Double(overallRating),
                              content: Double(contentRating),
                              workload: Double(workloadRating),
                              assessment: Double(assessmentRating))
            _ = try await DKRequests.postReview(courseId: courseId,
                                                content: content,
                                                title: title,
                                                rank: rank)
        }
    }
}

struct DKPostSheet_Previews: PreviewProvider {
    static var previews: some View {
        DKPostSheet(courseGroup: Bundle.main.decodeData("course")!)
    }
}
