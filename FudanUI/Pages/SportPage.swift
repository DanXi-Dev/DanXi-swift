import SwiftUI
import FudanKit
import ViewUtils

struct SportPage: View {
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
                    Form {
                        List {
                            ForEach(sportData.exerciseLogs) { log in
                                LabeledContent(log.category) {
                                    Text("\(log.date) \(log.status)")
                                        .font(.callout)
                                }
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showExerciseSheet = false
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                    .navigationTitle("Exercise Logs")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showExamSheet) {
                NavigationStack {
                    Form {
                        if let exam = sportData.exam {
                            List {
                                ForEach(exam.logs) { log in
                                    LabeledContent(log.name) {
                                        Text(log.date)
                                            .font(.callout)
                                    }
                                }
                            }
                        } else {
                            Text("No Data")
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showExamSheet = false
                            } label: {
                                Text("Done")
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

fileprivate struct SportData {
    let exercises: [Exercise]
    let exerciseLogs: [ExerciseLog]
    let exam: SportExam?
}
