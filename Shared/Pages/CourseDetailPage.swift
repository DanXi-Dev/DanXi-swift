import SwiftUI

struct CourseDetailPage: View {
    @State var courseGroup: DKCourseGroup
    @State var showCourseInfo = true
    
    
    @State var teacherSelected: String = ""
    @State var semesterSelected: DKSemester = DKSemester.empty
    
    @State var initialized = false
    @State var loading = true
    @State var errorInfo = ErrorInfo()
    
    var filteredReviews: [DKReview] {
        var reviewList: [DKReview] = []
        for course in courseGroup.courses {
            let teacherMatched = teacherSelected.isEmpty || teacherSelected == course.teachers
            let semesterMatched = semesterSelected == DKSemester.empty || course.matchSemester(semesterSelected)
            
            if teacherMatched && semesterMatched {
                reviewList.append(contentsOf: course.reviews)
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
    
    init(courseGroup: DKCourseGroup) {
        self._courseGroup = State(initialValue: courseGroup)
    }
    
    init(courseGroup: DKCourseGroup, initialized: Bool) { // preview purpose
        self._courseGroup = State(initialValue: courseGroup)
        self._initialized = State(initialValue: initialized)
    }
    
    func loadReviews() async {
        do {
            loading = true
            defer { loading = false }
            self.courseGroup = try await NetworkRequests.shared.loadCourseGroup(id: courseGroup.id)
            initialized = true
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            errorInfo = error.localizedErrorDescription
        } catch {
            errorInfo = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                Text(courseGroup.code)
                    .foregroundColor(.secondary)
                Divider()
                courseInfo
                
                Divider()
                Text("Course Review")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                    .pickerStyle(.segmented)
                if initialized {
                    courseReview
                } else {
                    ListLoadingView(loading: $loading,
                                    errorDescription: errorInfo.description,
                                    action: loadReviews)
                    .padding()
                }
            }
            .padding(.horizontal)
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
        .navigationTitle(courseGroup.name)
        .task {
            await loadReviews()
        }
    }
    
    private var courseInfo: some View {
        DisclosureGroup(isExpanded: $showCourseInfo) {
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
    
    private var courseReview: some View {
        Group {
            courseReviewFilter
            
            if !filteredReviews.isEmpty {
                courseReviewSummary
            }
            
            ForEach(courseGroup.courses) { course in
                ForEach(course.reviews) { review in
                    let teacherMatched = teacherSelected.isEmpty || teacherSelected == course.teachers
                    let semesterMatched = semesterSelected == DKSemester.empty || course.matchSemester(semesterSelected)
                    
                    if teacherMatched && semesterMatched {
                        CourseReview(review: review, course: course)
                    }
                }
            }
            
            if filteredReviews.isEmpty {
                HStack {
                    Spacer()
                    Text("No Review")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top)
            }
            
            
        }
    }
    
    private var courseReviewSummary: some View {
        HStack(alignment: .top) {
            VStack {
                Text(String(format: "%.1f", filteredRank.overall))
                    .font(.system(size: 46.0, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.7))
                
                Text("Out of \(5)")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                RankView(rank: filteredRank)
                    .frame(width: 200)
                
                Text("\(filteredReviews.count) Reviews")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
                    .padding(.top, 4)
            }
        }
    }
    
    
    
    private var courseReviewFilter: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Professors", systemImage: "line.3.horizontal.decrease.circle")
                Picker(selection: $teacherSelected, label: Text("Filter Teacher")) {
                    Text("All Professors")
                        .tag("")
                    
                    ForEach(courseGroup.teachers, id: \.self) { teacher in
                        Text(teacher)
                            .tag(teacher)
                    }
                }
            }
            HStack {
                Label("Semester", systemImage: "line.3.horizontal.decrease.circle")
                Picker(selection: $semesterSelected, label: Text("Filter Semester")) {
                    
                    Text("All Semesters")
                        .tag(DKSemester.empty)
                    
                    ForEach(courseGroup.semesters) { semester in
                        Text(semester.formatted())
                            .tag(semester)
                    }
                }
            }
        }
        .font(.callout)
        .foregroundColor(.secondary)
    }
}

struct CourseDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                CourseDetailPage(courseGroup: PreviewDecode.decodeObj(name: "course")!, initialized: true)
            }
            NavigationView {
                CourseDetailPage(courseGroup: PreviewDecode.decodeObj(name: "course")!, initialized: true)
            }
            .preferredColorScheme(.dark)
        }
    }
}
