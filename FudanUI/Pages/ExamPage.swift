import FudanKit
import SwiftUI
import ViewUtils

struct ExamPage: View {
    @State var selectedExam: Exam? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AsyncContentView { _ in
            try await UndergraduateCourseAPI.getExams()
        } content: { exams in
            List {
                ForEach(exams) { exam in
                    Button {
                        selectedExam = exam
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exam.course)
                                    .fontWeight(.bold)
                                Text(exam.type)
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(exam.time)
                                    .foregroundColor(.secondary)
                                Text(exam.location)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exams")
            .sheet(item: $selectedExam) { exam in
                ExamDetailSheet(exam: exam)
                    .presentationDetents([.medium])
            }
        }
        .navigationTitle("Exams")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct ExamDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exam: Exam

    var body: some View {
        NavigationStack {
            List {
                HStack {
                    Text(exam.course)
                        .lineLimit(1)
                        .fontWeight(.bold)
                    Spacer()
                    Text(exam.type)
                }
                HStack {
                    Text("Exam Type")
                    Spacer()
                    Text(exam.method)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Time")
                    Spacer()
                    Text(exam.time)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Location")
                    Spacer()
                    Text(exam.location)
                        .foregroundColor(.secondary)
                }
            }
            .labelStyle(.titleOnly)
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .navigationTitle("Exam Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ExamPage()
}
