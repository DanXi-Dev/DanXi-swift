import SwiftUI

struct FDScorePage: View {
    var body: some View {
        AsyncContentView { () -> [FDSemester] in
            try await FDAcademicAPI.login()
            return try await FDAcademicAPI.getSemesters()
        } content: { semesters in
            ScorePageContent(semesters)
        }
    }
}

fileprivate struct ScorePageContent: View {
    private let semesters: [FDSemester]
    @State private var semester: FDSemester
    
    init(_ semesters: [FDSemester]) {
        self.semesters = semesters
        self._semester = State(initialValue: semesters.last!)
    }
    
    var body: some View {
        List {
            SemesterPicker(semesters: semesters, semester: $semester)
            ScoreList(semester: semester)
        }
        .navigationTitle("Exams & Score")
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
            Text(score.grade)
                .fontWeight(.bold)
                .font(.title3)
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
