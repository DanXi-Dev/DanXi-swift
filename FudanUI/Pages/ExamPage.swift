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
                                Text(verbatim: "\(exam.date)  \(exam.time)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                if !exam.type.contains("无") {
                                    Text(exam.type)
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                                if !exam.location.contains("无") {
                                    Text(exam.location)
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
                    Spacer()
                    Text(exam.type)
                }
                HStack {
                    Text("Exam Type", bundle: .module)
                    Spacer()
                    Text(exam.method)
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
            .listStyle(.insetGrouped)
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
