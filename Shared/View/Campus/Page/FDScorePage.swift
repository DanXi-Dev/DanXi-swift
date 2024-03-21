import SwiftUI

struct FDScorePage: View {
    struct SemesterInfo {
        let semesters: [FDSemester]
        let currentSemester: FDSemester?
    }
    
    var body: some View {
        AsyncContentView { () -> SemesterInfo in
            try await FDAcademicAPI.login()
            let (semesters, currentId) = try await (FDAcademicAPI.getSemesters(), FDAcademicAPI.getCurrentSemesterId())
            let currentSemester = semesters.filter { $0.id == currentId }.first
            let info = SemesterInfo(semesters: semesters, currentSemester: currentSemester)
            return info
        } content: { info in
            ScorePageContent(info.semesters, current: info.currentSemester)
        }
    }
}

fileprivate struct ScorePageContent: View {
    private let semesters: [FDSemester]
    @State private var semester: FDSemester
    
    init(_ semesters: [FDSemester], current: FDSemester?) {
        self.semesters = semesters
        self._semester = State(initialValue: current ?? semesters.last!)
    }
    
    var body: some View {
        List {
            SemesterPicker(semesters: semesters, semester: $semester)
            ScoreList(semester: semester)
        }
        .navigationTitle("Exams & Score")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct ScoreList: View {
    let semester: FDSemester
    
    var body: some View {
        AsyncContentView(style: .widget) { () -> [FDScore] in
            return try await FDAcademicAPI.getScore(semester: semester.id)
        } content: { scores in
            Section {
                ForEach(scores) { score in
                    ScoreView(score: score)
                }
            } footer: {
                if scores.isEmpty {
                    HStack {
                        Spacer()
                        Text("No Score Entry")
                        Spacer()
                    }
                }
            }
        }
        .id(semester.id) // force reload after semester change
    }
}

fileprivate struct ScoreView: View {
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
            Text(score.grade.padding(toLength: max(2, score.grade.count), withPad: " ", startingAt: 0)) // Align monospaced grades
                .fontWeight(.bold)
                .font(.title3.monospaced())
        }
    }
}

fileprivate struct SemesterPicker: View {
    let semesters: [FDSemester]
    @Binding var semester: FDSemester
    
    private func moveSemester(offset: Int) {
        guard let idx = semesters.firstIndex(of: semester) else { return }
        if (0..<semesters.count).contains(idx + offset) {
            semester = semesters[idx + offset]
        }
    }
    
    var body: some View {
        Section {
            HStack {
                Button {
                    moveSemester(offset: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .disabled(semester == semesters.first)
                
                Spacer()
                
                Menu(semester.formatted()) {
                    ForEach(semesters) { semester in
                        Button(semester.formatted()) {
                            self.semester = semester
                        }
                    }
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    moveSemester(offset: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .disabled(semester == semesters.last)
            }
            .font(.body)
            .listRowBackground(Color.clear)
        }
    }
}
