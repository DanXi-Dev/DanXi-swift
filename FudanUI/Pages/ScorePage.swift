import SwiftUI
import FudanKit
import ViewUtils

struct ScorePage: View {
    struct SemesterInfo {
        let semesters: [Semester]
        let currentSemester: Semester?
    }
    
    var body: some View {
        AsyncContentView { _ in
            let (semesters, currentSemester) = try await UndergraduateCourseStore.shared.getRefreshedSemesters()
            let info = SemesterInfo(semesters: semesters, currentSemester: currentSemester)
            return info
        } content: { info in
            ScorePageContent(info.semesters, current: info.currentSemester)
        }
    }
}

fileprivate struct ScorePageContent: View {
    private let semesters: [Semester]
    @State private var semester: Semester
    
    init(_ semesters: [Semester], current: Semester?) {
        self.semesters = semesters
        self._semester = State(initialValue: current ?? semesters.last!)
    }
    
    var body: some View {
        List {
            SemesterPicker(semesters: semesters.sorted(), semester: $semester)
            ScoreList(semester: semester)
        }
        .navigationTitle("Exams & Score")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct ScoreList: View {
    let semester: Semester
    
    var body: some View {
        AsyncContentView(style: .widget) { _ in
            return try await UndergraduateCourseAPI.getScore(semester: semester.semesterId)
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
        .id(semester.semesterId) // force reload after semester change
    }
}

fileprivate struct ScoreView: View {
    let score: Score
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(score.courseType)
                    .font(.callout)
                    .foregroundColor(.secondary)
                Text(score.courseName)
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
    let semesters: [Semester]
    @Binding var semester: Semester
    
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
                
                Menu(semester.name) {
                    ForEach(semesters, id: \.semesterId) { semester in
                        Button(semester.name) {
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
