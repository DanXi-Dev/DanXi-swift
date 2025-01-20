import MarkdownUI
import SwiftUI
import ViewUtils
import DanXiKit

public struct ReviewPage: View {
    @Namespace private var namespace
    @State private var selectedMedal: Achievement?
    let course: Course
    let review: Review
    
    public var body: some View {
        ReviewPageContent(course: course, review: review, selectedMedal: $selectedMedal, namespace: namespace)
            .overlay {
                if let selectedMedal {
                    MedalPage(medal: selectedMedal, selectedMedal: $selectedMedal, namespace: namespace)
                }
            }
            .navigationBarBackButtonHidden(selectedMedal != nil)
    }
}


struct ReviewPageContent: View {
    @Environment(\.dismiss) private var dismiss
    
    let course: Course
    @State private var review: Review
    @State private var showEditSheet = false
    @State private var showDeleteReviewAlert = false
    @Binding var selectedMedal: Achievement?
    let namespace: Namespace.ID
    @EnvironmentObject var model: CourseModel
    
    init(course: Course, review: Review, selectedMedal: Binding<Achievement?>, namespace: Namespace.ID) {
        self.course = course
        self._review = State(initialValue: review)
        self._selectedMedal = selectedMedal
        self.namespace = namespace
    }
    
    @ViewBuilder private var likeButtons: some View {
        AsyncButton {
            try await withHaptics {
                let upvote = review.vote >= 0
                self.review = try await CurriculumAPI.voteReview(id: review.id, upvote: upvote)
                model.updateReview(self.review, forCourseId: course.id)
            }
        } label: {
            Image(systemName: "arrow.up")
                .padding(.horizontal)
                .foregroundColor(.primary)
        }
        .buttonStyle(.borderedProminent)
        .tint(review.vote == 1 ? .accentColor : .secondarySystemBackground)
        
        AsyncButton {
            try await withHaptics {
                let upvote = review.vote <= 0
                self.review = try await CurriculumAPI.voteReview(id: review.id, upvote: !upvote)
                model.updateReview(self.review, forCourseId: course.id)
            }
        } label: {
            Image(systemName: "arrow.down")
                .padding(.horizontal)
                .foregroundColor(.primary)
        }
        .buttonStyle(.borderedProminent)
        .tint(review.vote == -1 ? .accentColor : .secondarySystemBackground)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(review.title)
                    .font(.title)
                    .bold()
                HStack {
                    CourseTagView {
                        Text(course.teachers)
                    }
                    CourseTagView {
                        Text(course.formattedSemester)
                    }
                    Spacer()
                    
                    Label(String(review.remark), systemImage: "arrow.up")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                RatingView(rank: review.rank)
                    .padding(.bottom, 6)
                
                Text((try? AttributedString(markdown: review.content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                    .inlineOnlyPreservingWhitespace))) ?? AttributedString(review.content))
                .font(.body.leading(.loose))
                
                HStack {
                    likeButtons
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(review.timeUpdated.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
                
                let medals: [String] = ["蛋壳开荒者"]
                
                
                LazyVGrid (columns: [GridItem(.fixed(35)), GridItem(.fixed(35)), GridItem(.fixed(35))], alignment: .trailing){
                    ForEach (medals, id: \.self) { medal in
                        Image(medal, bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                if let medal = review.extra.achievements.first(where: { $0.name == medal }) {
                                    withAnimation {
                                        selectedMedal = medal
                                    }
                                }
                            }
                            .matchedGeometryEffect(id: medal, in: namespace)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
            }
        }
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline) // this is to remove the top padding
        .sheet(isPresented: $showEditSheet) {
            CurriculumEditSheet(courseGroup: model.courseGroup, course: course, review: $review)
        }
        .alert(String(localized: "Delete Review", bundle: .module), isPresented: $showDeleteReviewAlert) {
            Button(role: .destructive) {
                Task {
                    try await CurriculumAPI.deleteReview(reviewId: review.id)
                    dismiss()
                }
            } label: {
                Text("Confirm", bundle: .module)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if review.isMe {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.headline)
                    }
                    
                    Button {
                        showDeleteReviewAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.headline)
                    }
                }
            }
        }
    }
}
