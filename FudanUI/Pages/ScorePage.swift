import FudanKit
import SwiftUI
import ViewUtils
import Utils

struct ScorePage: View {
    struct SemesterInfo {
        let semesters: [Semester]
        let currentSemester: Semester?
    }
    
    var body: some View {
        AsyncContentView {
            let (semesters, currentSemester) = try await UndergraduateCourseStore.shared.getRefreshedSemesters()
            if semesters.isEmpty {
                let description = String(localized: "Semester list is empty.", bundle: .module)
                throw LocatableError(description)
            }
            let info = SemesterInfo(semesters: semesters, currentSemester: currentSemester)
            return info
        } content: { info in
            ScorePageContent(info.semesters, current: info.currentSemester)
        }
        .navigationTitle(String(localized: "Exams & Score", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct ScorePageContent: View {
    private let semesters: [Semester]
    private let previewScores: [Score]?
    @State private var semester: Semester
    @State private var selectedScore: Score?
    
    init(_ semesters: [Semester], current: Semester?, previewScores: [Score]? = nil) {
        self.semesters = semesters
        self._semester = State(initialValue: current ?? semesters.last!)
        self.previewScores = previewScores
    }
    
    var body: some View {
        List {
            SemesterPicker(semesters: semesters.sorted(), semester: $semester)
            ScoreList(semester: semester, selectedScore: $selectedScore, previewScores: previewScores)
        }
        .sheet(item: $selectedScore) { score in
            ScoreDetailSheet(score: score)
        }
    }
}

fileprivate struct ScoreList: View {
    let semester: Semester
    @Binding var selectedScore: Score?
    let previewScores: [Score]?
        
    init(semester: Semester, selectedScore: Binding<Score?>, previewScores: [Score]?) {
        self.semester = semester
        self._selectedScore = selectedScore
        self.previewScores = previewScores
    }
    
    var body: some View {
        AsyncContentView(style: .widget) {
            if let previewScores {
                return previewScores
            }
            return try await UndergraduateCourseAPI.getScore(semester: semester.semesterId)
        } content: { scores in
            Section {
                ForEach(scores) { score in
                    Button {
                        selectedScore = score
                    } label: {
                        ScoreView(score: score)
                    }
                    .tint(.primary)
                }
            } footer: {
                if scores.isEmpty {
                    HStack {
                        Spacer()
                        Text("No Score Entry", bundle: .module)
                        Spacer()
                    }
                }
            }
        }
        .id(semester.semesterId) // force reload after semester change
    }
}

fileprivate struct ScoreDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let score: Score
    
    var body: some View {
        NavigationStack {
            List {
                HStack {
                    VStack(alignment: .leading) {
                        Text(score.courseId)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(score.courseName)
                            .lineLimit(1)
                            .fontWeight(.bold)
                            .font(.title3)
                    }
                    Spacer()
                    Text(score.grade)
                        .fontWeight(.bold)
                        .font(.title3.monospaced())
                }
                HStack {
                    Text("Grade Point", bundle: .module)
                    Spacer()
                    Text(score.gradePoint)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Course Credit", bundle: .module)
                    Spacer()
                    Text(score.courseCredit)
                        .foregroundColor(.secondary)
                }
            }
            .labelStyle(.titleOnly)
            #if !os(watchOS)
            .listStyle(.insetGrouped)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
            .navigationTitle(String(localized: "Exam Detail", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
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
        if (0 ..< semesters.count).contains(idx + offset) {
            semester = semesters[idx + offset]
        }
    }
    
    var body: some View {
        Section {
            #if os(watchOS)
            
            Picker(selection: $semester) {
                ForEach(semesters, id: \.semesterId) { semester in
                    Text(semester.name)
                        .tag(semester)
                }
            } label: {
                Text("Semester", bundle: .module)
            }
            
            #else
            
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
            
            #endif
        }
        
        
    }
}

#Preview {
    let semesters: [Semester] = decodePreviewData(filename: "semesters")
    
    ScorePageContent(semesters.sorted(), current: semesters.sorted().last!, previewScores: decodePreviewData(filename: "score"))
        .previewPrepared()
}
