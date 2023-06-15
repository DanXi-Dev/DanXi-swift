import SwiftUI

struct FDSportPage: View {    
    var body: some View {
        AsyncContentView { () -> (FDExercise, FDSportExam) in
            try await FDSportAPI.login()
            let exam = try await FDSportAPI.fetchExamData()
            let exercise = try await FDSportAPI.fetchExerciseData()
            return (exercise, exam)
        } content: { (exercise, exam) in
            List {
                ExerciseSection(exercise: exercise)
                ExamSection(exam: exam)
            }
            .navigationTitle("PE Curriculum")
        }
    }
}


fileprivate struct ExerciseSection: View {
    let exercise: FDExercise
    @State private var showSheet = false
    
    var body: some View {
        Section {
            ForEach(exercise.exerciseItems) { item in
                LabeledContent(item.name) {
                    Text("\(item.count)")
                }
            }
        } header: {
            HStack {
                Text("Extracurricular Activities")
                    .font(.headline)
                Spacer()
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showSheet) {
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
    }
}


fileprivate struct ExamSection: View {
    let exam: FDSportExam
    @State private var showSheet = false
    
    
    var body: some View {
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
                    .font(.headline)
                Spacer()
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showSheet) {
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
