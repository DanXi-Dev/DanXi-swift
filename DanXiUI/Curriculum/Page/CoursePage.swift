import SwiftUI
import ViewUtils
import DanXiKit

// MARK: - View

struct CoursePage: View {
    let courseGroup: CourseGroup
    @State private var showPostSheet = false
    
    init(courseGroup: CourseGroup) {
        self.courseGroup = courseGroup
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                Text(courseGroup.code)
                    .foregroundColor(.secondary)
                
                Divider()
                
                CourseInfo(courseGroup: courseGroup)
                
                Divider()
                
                AsyncContentView(style: .widget) { _ in
                    return try await CurriculumAPI.getCourseGroup(id: courseGroup.id)
                } content: { courseGroup in
                    ReviewSection(courseGroup)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle(courseGroup.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem {
                Button {
                    showPostSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showPostSheet) {
            CurriculumPostSheet(courseGroup: courseGroup)
        }
    }
}

fileprivate struct CourseInfo: View {
    let courseGroup: CourseGroup
    @State private var expand = true
    
    var body: some View {
        DisclosureGroup(isExpanded: $expand) {
            VStack(alignment: .leading) {
                Label("Professors", systemImage: "person.fill")
                Text(courseGroup.teachers.formatted())
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Credit", systemImage: "a.square.fill")
                Text("\(String(courseGroup.courses.first?.credit ?? 0)) Credit")
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Campus", systemImage: "building.fill")
                Text(courseGroup.campus)
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
                
                Label("Department", systemImage: "building.columns.fill")
                Text(courseGroup.department)
                    .foregroundColor(.secondary)
                    .padding(.leading, 25.0)
                    .padding(.bottom, 6.0)
            }
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .font(.callout)
            .padding(.top, 15)
        } label: {
            Text("Course Information")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}

fileprivate struct ReviewSection: View {
    @StateObject private var model: CourseModel
    
    init(_ courseGroup: CourseGroup) {
        let model = CourseModel(courseGroup)
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        Group {
            Text("Course Review")
                .font(.title3)
                .fontWeight(.bold)
            
            ReviewFilter()
            
            if !model.filteredReviews.isEmpty {
                ReviewSummary()
                
                ForEach(model.courseGroup.courses) { course in
                    ForEach(course.reviews) { review in
                        let teacherMatched = model.teacher.isEmpty || model.teacher == course.teachers
                        let semesterMatched = model.semester == Semester.empty || course.matchSemester(model.semester)
                        
                        if teacherMatched && semesterMatched {
                            NavigationLink(destination: ReviewPage(course: course, review: review).environmentObject(model)) {
                                ReviewView(review: review, course: course)
                            }
                        }
                    }
                }
            } else {
                Spacer()
                Text("No Review")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .environmentObject(model)
    }
}

fileprivate struct ReviewFilter: View {
    @EnvironmentObject private var model: CourseModel
    
    var body: some View {
        Group {
            LabeledContent {
                Picker(selection: $model.teacher, label: Text("Filter Teacher")) {
                    Text("All Professors")
                        .tag("")
                    
                    ForEach(model.courseGroup.teachers, id: \.self) { teacher in
                        Text(teacher)
                            .tag(teacher)
                    }
                }
            } label: {
                Label("Professors", systemImage: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.secondary)
            }
            
            LabeledContent {
                Picker(selection: $model.semester, label: Text("Filter Semester")) {
                    Text("All Semesters")
                        .tag(Semester.empty)
                    
                    ForEach(model.courseGroup.semesters) { semester in
                        Text(semester.formatted())
                            .tag(semester)
                    }
                }
            } label: {
                Label("Semester", systemImage: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.secondary)
            }
        }
    }
}

fileprivate struct ReviewSummary: View {
    @EnvironmentObject private var model: CourseModel
    
    var body: some View {
        HStack(alignment: .top) {
            VStack {
                Text(String(format: "%.1f", model.filteredRank.overall))
                    .font(.system(size: 46.0, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.7))
                
                Text("Out of \(5)")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .fixedSize()
            
            Spacer()
            
            VStack(alignment: .trailing) {
                RatingView(rank: model.filteredRank)
                
                Text("\(model.filteredReviews.count) Reviews")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
                    .padding(.top, 4)
            }
        }
    }
}


// MARK: - Model

class CourseModel: ObservableObject {
    @Published var courseGroup: CourseGroup
    @Published var teacher = ""
    @Published var semester = Semester.empty
    
    init(_ courseGroup: CourseGroup) {
        self.courseGroup = courseGroup
    }
    
    var filteredReviews: [Review] {
        var reviewList: [Review] = []
        for course in courseGroup.courses {
            let teacherMatched = teacher.isEmpty || teacher == course.teachers
            let semesterMatched = semester == Semester.empty || course.matchSemester(semester)
            
            if teacherMatched && semesterMatched {
                reviewList += course.reviews
            }
        }
        
        return reviewList
    }
    
    var filteredRank: Rank {
        var content = 0.0, overall = 0.0, workload = 0.0, assessment = 0.0
        for review in filteredReviews {
            let rank = review.rank
            overall += rank.overall
            content += rank.content
            workload += rank.workload
            assessment += rank.assessment
        }
        let count = Double(filteredReviews.count)
        return Rank(overall: overall / count, content: content / count, workload: workload / count, assessment: assessment / count)
    }
    
    func updateReview(_ updatedReview: Review, forCourseId courseId: Int) {
        if let courseIndex = self.courseGroup.courses.firstIndex(where: { $0.id == courseId }),
           let reviewIndex = self.courseGroup.courses[courseIndex].reviews.firstIndex(where: { $0.id == updatedReview.id }) {
            self.courseGroup.courses[courseIndex].reviews[reviewIndex] = updatedReview
        }
    }
}

