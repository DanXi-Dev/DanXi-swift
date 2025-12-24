import FudanKit
import SwiftUI
import ViewUtils

struct ExamPage: View {
    @State var selectedExam: Exam? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AsyncContentView {
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
                                    .foregroundColor(exam.isFinished ? .secondary : .primary)
                                Text(verbatim: "\(exam.semester) \(exam.date)  \(exam.time)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                    if !exam.type.contains("无") {
                                        Text(exam.type)
                                            .fontWeight(.bold)
                                            .foregroundColor(exam.isFinished ? .secondary : .primary)
                                            .font(.footnote)
                                    }
                                    if !exam.location.contains("无") || !exam.method.contains("无") {
                                        let locationText = exam.location
                                        let methodText = exam.method
                                        let combinedText = !methodText.contains("无") ? "\(locationText)(\(methodText))" : locationText
                                        Text(combinedText)
                                            .foregroundColor(.secondary)
                                            .font(.footnote)
                                    }
                                }
                        }
                    }
                    .tint(.primary)
                }
            }
            .navigationTitle(String(localized: "Exams", bundle: .module))
            .sheet(item: $selectedExam) { exam in
                ExamDetailSheet(exam: exam)
                    .presentationDetents([.medium])
            }
        }
        .navigationTitle(String(localized: "Exams", bundle: .module))
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
                        .foregroundColor(exam.isFinished ? .secondary : .primary)
                    Spacer()
                    Text(exam.type)
                        .fontWeight(.bold)
                        .foregroundColor(exam.isFinished ? .secondary : .primary)
                }
                HStack {
                    Text("Exam Type", bundle: .module)
                    Spacer()
                    Text(exam.method)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Semester", bundle: .module)
                    Spacer()
                    Text(exam.semester)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Date", bundle: .module)
                    Spacer()
                    Text(exam.date)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Time", bundle: .module)
                    Spacer()
                    Text(exam.time)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Location", bundle: .module)
                    Spacer()
                    Text(exam.location)
                        .foregroundColor(.secondary)
                }
            }
            .labelStyle(.titleOnly)
            #if !os(watchOS)
            .listStyle(.insetGrouped)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
            .navigationTitle(String(localized: "Exam Detail", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
