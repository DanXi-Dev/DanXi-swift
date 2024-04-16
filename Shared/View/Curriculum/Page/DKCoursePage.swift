import SwiftUI
import ViewUtils

// MARK: - View

struct DKCoursePage: View {
    let courseGroup: DKCourseGroup
    @State private var showPostSheet = false
    
    init(courseGroup: DKCourseGroup) {
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
                    return try await DKRequests.loadCourseGroup(id: courseGroup.id)
                } content: { courseGroup in
                    ReviewSection(courseGroup)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .watermark()
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
            DKPostSheet(courseGroup: courseGroup)
        }
    }
}

fileprivate struct CourseInfo: View {
    let courseGroup: DKCourseGroup
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
    @StateObject private var model: DKCourseModel
    
    init(_ courseGroup: DKCourseGroup) {
        let model = DKCourseModel(courseGroup)
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
                        let semesterMatched = model.semester == DKSemester.empty || course.matchSemester(model.semester)
                        
                        if teacherMatched && semesterMatched {
                            let item = CurriculumReviewItem(course: course, review: review)
                            DetailLink(value: item) {
                                DKReviewView(review: review, course: course)
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
    @EnvironmentObject private var model: DKCourseModel
    
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
                        .tag(DKSemester.empty)
                    
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
    @EnvironmentObject private var model: DKCourseModel
    
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
                DKRatingView(rank: model.filteredRank)
                
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

class DKCourseModel: ObservableObject {
    let courseGroup: DKCourseGroup
    @Published var teacher = ""
    @Published var semester = DKSemester.empty
    
    init(_ courseGroup: DKCourseGroup) {
        self.courseGroup = courseGroup
    }
    
    var filteredReviews: [DKReview] {
        var reviewList: [DKReview] = []
        for course in courseGroup.courses {
            let teacherMatched = teacher.isEmpty || teacher == course.teachers
            let semesterMatched = semester == DKSemester.empty || course.matchSemester(semester)
            
            if teacherMatched && semesterMatched {
                reviewList += course.reviews
            }
        }
        
        return reviewList
    }
    
    var filteredRank: DKRank {
        var content = 0.0, overall = 0.0, workload = 0.0, assessment = 0.0
        for review in filteredReviews {
            let rank = review.rank
            overall += rank.overall
            content += rank.content
            workload += rank.workload
            assessment += rank.assessment
        }
        let count = Double(filteredReviews.count)
        return DKRank(overall: overall / count,
                      content: content / count,
                      workload: workload / count,
                      assessment: assessment / count)
    }
}

