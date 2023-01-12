import SwiftUI

struct FDSportPage: View {
    @State var exerciseInfo: ExerciseInfo? = nil
    @State var examInfo: SportExamInfo? = nil
    
    @State var showExerciseSheet = false
    @State var showExamSheet = false
    
    func loadAll() async throws {
        try await SportRequest.login()
        self.examInfo = try await SportRequest.fetchExamData()
        self.exerciseInfo = try await SportRequest.fetchExerciseData()
    }
    
    
    var body: some View {
        LoadingPage(action: loadAll) {
            List {
                if let exerciseInfo = exerciseInfo {
                    Section {
                        ForEach(exerciseInfo.exerciseItems) { item in
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
                                showExerciseSheet = true
                            } label: {
                                Image(systemName: "info.circle")
                            }
                        }
                    }
                    .sheet(isPresented: $showExerciseSheet) {
                        NavigationStack {
                            List {
                                ForEach(exerciseInfo.exerciseLogs) { log in
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
                
                if let examInfo = examInfo {
                    Section {
                        LabeledContent("Total Score") {
                            Text("\(Int(examInfo.total)) (\(examInfo.evaluation))")
                        }
                        
                        ForEach(examInfo.items) { item in
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
                                showExamSheet = true
                            } label: {
                                Image(systemName: "info.circle")
                            }
                        }
                    }
                    .sheet(isPresented: $showExamSheet) {
                        NavigationStack {
                            List {
                                ForEach(examInfo.logs) { log in
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
            .navigationTitle("PE Curriculum")

        }
    }
}

struct SportPage_Previews: PreviewProvider {
    static var previews: some View {
        FDSportPage()
    }
}
