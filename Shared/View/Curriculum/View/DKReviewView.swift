import MarkdownUI
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
                        .frame(height: 14)
                        .offset(x: 0, y: -4.4)
                }

                Spacer()

                Label("\(String(review.remark))", systemImage: "arrow.up")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)

            Text((try? AttributedString(markdown: review.content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                .inlineOnlyPreservingWhitespace))) ?? AttributedString(review.content))
                .multilineTextAlignment(.leading)
                .font(.body.leading(.standard))
                .lineLimit(6)

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
