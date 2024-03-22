import SwiftUI

struct FDSportPage: View {
    @State private var showExerciseSheet = false
    @State private var showExamSheet = false
    
    var body: some View {
        AsyncContentView { () -> (FDExercise, FDSportExam) in
            try await FDSportAPI.login()
            async let exam = FDSportAPI.fetchExamData()
            async let exercise = FDSportAPI.fetchExerciseData()
            return try await (exercise, exam)
        } content: { (exercise, exam) in
            List {
                Section {
                    ForEach(exercise.exerciseItems) { item in
                        LabeledContent(item.name) {
                            Text("\(item.count)")
                        }
                    }
                } header: {
                    HStack {
                        Text("Extracurricular Activities")
                        Spacer()
                        Button {
                            showExerciseSheet = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.footnote)
                        }
                    }
                }
                
                Section {
                    LabeledContent("Total Score") {
                        Text("\(Int(exam.total)) (\(exam.evaluation))")
                    }
                    
                    ForEach(exam.items) { item in
                        LabeledContent(item.name) {
                            Text(item.result)
                        }
                    }
                } header: {
                    HStack {
                        Text("PE Exam")
                        Spacer()
                        Button {
                            showExamSheet = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.footnote)
                        }
                    }
                }
            }
            .navigationTitle("PE Curriculum")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExerciseSheet) {
                NavigationStack {
                    List {
                        ForEach(exercise.exerciseLogs) { log in
                            LabeledContent(log.name) {
                                Text("\(log.date) \(log.status)")
                                    .font(.callout)
                            }
                        }
                    }
                    .navigationTitle("Exercise Logs")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showExamSheet) {
                NavigationStack {
                    List {
                        ForEach(exam.logs) { log in
                            LabeledContent(log.name) {
                                Text(log.date)
                                    .font(.callout)
                            }
                        }
                    }
                    .navigationTitle("PE Exam Logs")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}
