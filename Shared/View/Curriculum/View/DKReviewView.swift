import SwiftUI

struct DKReviewView: View {
    let review: DKReview
    let course: DKCourse
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(review.title)
                        .font(.headline)
                        .lineLimit(1)
                    DKStarsView(rating: CGFloat(review.rank.overall))
                        .frame(width: 60)
                        .offset(x: 0, y: -6)
                }

                Spacer()
                
                Label("\(String(review.remark))", systemImage: "arrow.up")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Text((try? AttributedString(markdown: review.content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                    .inlineOnlyPreservingWhitespace))) ?? AttributedString(review.content))
                .multilineTextAlignment(.leading)
                .lineLimit(10)

            HStack {
                DKTagView {
                    Text(course.teachers)
                }
                DKTagView {
                    Text(course.formattedSemester)
                }
                Spacer()
                Text(review.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(7.0)
        .padding(.vertical, 3)
    }
}
