import SwiftUI

struct FDScorePage: View {
    @State var semesters: [FDSemester] = []
    @State var semester: FDSemester?
    
    @State var scoreList: [FDScore] = []
    @State var scoreLoading = false
    @State var scoreLoadingError = ""
    
    func initialLoad() async throws {
        try await FDAcademicAPI.login()
        semesters = try await FDAcademicAPI.getSemesters()
        semester = semesters.last
    }
    
    func loadScoreList() async {
        do {
            guard let semester = semester else { return }
            scoreLoading = true
            defer { scoreLoading = false }
            scoreList = try await FDAcademicAPI.getScore(semester: semester.id)
        } catch {
            scoreLoadingError = error.localizedDescription
        }
    }
    
    func moveSemester(prev: Bool) {
        guard let semester = semester else { return }
        for i in 0..<semesters.count {
            if semesters[i] == semester {
                let newIndex = prev ? i - 1 : i + 1
                self.semester = semesters[(0..<semesters.count).contains(newIndex) ? newIndex : i]
            }
        }
    }
    
    var body: some View {
        LoadingPage(action: initialLoad) {
            List {
                semesterPicker
                
                if scoreLoading {
                    Section {
                        
                    } footer: {
                        LoadingFooter(loading: $scoreLoading, errorDescription: scoreLoadingError, action: loadScoreList)
                    }
                } else {
                    scoreListView
                }
            }
            .navigationTitle("Exams & Score")
            .onChange(of: semester) { semester in
                Task { @MainActor in
                    await loadScoreList()
                }
            }
        }
    }
    
    @ViewBuilder
    var semesterPicker: some View {
        if let semester = semester {
            Section {
                
            } header: {
                HStack {
                    Button {
                        moveSemester(prev: true)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(semester == semesters.first)
                    
                    Spacer()
                    
                    Menu(String(localized: semester.formatted())) {
                        ForEach(semesters) { semester in
                            Button(String(localized: semester.formatted())) {
                                self.semester = semester
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    Spacer()
                    Button {
                        moveSemester(prev: false)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(semester == semesters.last)
                }
                .font(.body)
            }
        }
    }
    
    var scoreListView: some View {
        Section {
            ForEach(scoreList) { score in
                FDScoreEntryView(score: score)
            }
        } footer: {
            if scoreList.isEmpty {
                HStack {
                    Spacer()
                    Text("No Score Entry")
                    Spacer()
                }
                
            }
        }
    }
}

struct FDScoreEntryView: View {
    let score: FDScore
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(score.type)
                    .font(.callout)
                    .foregroundColor(.secondary)
                Text(score.name)
                    .font(.headline)
            }
            Spacer()
            Text(score.grade)
                .fontWeight(.bold)
                .font(.title3)
        }
    }
}

struct FDScorePage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FDScorePage()
        }
    }
}
