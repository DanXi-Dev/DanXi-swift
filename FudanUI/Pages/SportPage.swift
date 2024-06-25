import SwiftUI
import FudanKit
import ViewUtils

struct SportPage: View {
    @State private var showExerciseSheet = false
    @State private var showExamSheet = false
    
    var body: some View {
        AsyncContentView {
            let (exercises, logs) = try await SportStore.shared.getCachedExercises()
            let exam = try? await SportStore.shared.getCachedExam() // when this fails, user can still view exercise data
            return SportData(exercises: exercises, exerciseLogs: logs, exam: exam)
        } refreshAction: {
            let (exercises, logs) = try await SportStore.shared.getRefreshedExercises()
            let exam = try? await SportStore.shared.getRefreshedExam() // when this fails, user can still view exercise data
            return SportData(exercises: exercises, exerciseLogs: logs, exam: exam)
        } content: { (sportData: SportData) in
            List {
                Section {
                    ForEach(sportData.exercises) { exercise in
                        LabeledContent(exercise.category) {
                            Text(verbatim: "\(exercise.count)")
                        }
                    }
                } header: {
                    HStack {
                        Text("Extracurricular Activities", bundle: .module)
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
                        LabeledContent {
                            Text("\(Int(exam.total)) (\(exam.evaluation))")
                        } label: {
                            Text("Total Score", bundle: .module)
                        }
                        
                        ForEach(exam.items) { item in
                            LabeledContent(item.name) {
                                Text(item.result)
                            }
                        }
                    } header: {
                        HStack {
                            Text("PE Exam", bundle: .module)
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
                                Text("Done", bundle: .module)
                            }
                        }
                    }
                    .navigationTitle(String(localized: "Exercise Logs", bundle: .module))
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
                            Text("No Data", bundle: .module)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showExamSheet = false
                            } label: {
                                Text("Done", bundle: .module)
                            }
                        }
                    }
                    .navigationTitle(String(localized: "PE Exam Logs", bundle: .module))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .navigationTitle(String(localized: "PE Curriculum", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct SportData {
    let exercises: [Exercise]
    let exerciseLogs: [ExerciseLog]
    let exam: SportExam?
}
