import SwiftUI
import FudanKit

struct FDSportPage: View {
    @State private var showExerciseSheet = false
    @State private var showExamSheet = false
    
    var body: some View {
        AsyncContentView { () -> SportData in
            let (exercises, logs) = try await SportStore.shared.getCachedExercises()
            let exam = try? await SportStore.shared.getCachedExam() // when this fails, user can still view exercise data
            return SportData(exercises: exercises, exerciseLogs: logs, exam: exam)
        } content: { (sportData: SportData) in
            List {
                Section {
                    ForEach(sportData.exercises) { exercise in
                        LabeledContent(exercise.category) {
                            Text("\(exercise.count)")
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
                
                if let exam = sportData.exam {
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
            }
            .navigationTitle("PE Curriculum")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExerciseSheet) {
                NavigationStack {
                    List {
                        ForEach(sportData.exerciseLogs) { log in
                            LabeledContent(log.category) {
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
                if let exam = sportData.exam {
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
}

fileprivate struct SportData {
    let exercises: [Exercise]
    let exerciseLogs: [ExerciseLog]
    let exam: SportExam?
}
