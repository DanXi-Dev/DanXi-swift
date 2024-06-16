import SwiftUI
import ViewUtils
import FudanKit

struct ExamPage: View {
    var body: some View {
        AsyncContentView {
            try await UndergraduateCourseAPI.getExams()
        } content: { exams in
            List {
                ForEach(exams) { exam in
                    Text(exam.course)
                }
            }
            .navigationTitle("Exams")
        }
    }
}

#Preview {
    ExamPage()
}
