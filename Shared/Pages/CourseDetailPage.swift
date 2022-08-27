import SwiftUI

struct CourseDetailPage: View {
    @State var courseGroup: DKCourseGroup
    @State var showCourseInfo = true
    @State var initialized = false
    
    init(courseGroup: DKCourseGroup) {
        self._courseGroup = State(initialValue: courseGroup)
    }
    
    init(courseGroup: DKCourseGroup, initialized: Bool) { // preview purpose
        self._courseGroup = State(initialValue: courseGroup)
        self._initialized = State(initialValue: initialized)
    }
    
    var filteredReviews: [DKReview] {
        return courseGroup.reviews // TODO: filter this
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
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
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
            do {
                self.courseGroup = try await NetworkRequests.shared.loadCourseGroup(id: courseGroup.id)
                initialized = true
            } catch {
                print("DANXI-DEBUG: load course group failed")
            }
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
            
            courseReviewSummary
            
            ForEach(courseGroup.courses) { course in
                ForEach(course.reviews) { review in
                    CourseReview(review: review, course: course)
                }
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
        Text("") // TODO: filter course
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
