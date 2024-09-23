import MarkdownUI
import SwiftUI
import DanXiKit

struct ReviewView: View {
    let review: Review
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(review.title)
                        .font(.headline)
                        .lineLimit(1)
                    StarsView(rating: CGFloat(review.rank.overall))
                        .frame(height: 14)
                        .offset(x: 0, y: -4.4)
                }

                Spacer()

                Label(String(review.remark), systemImage: "arrow.up")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Text((try? AttributedString(markdown: review.content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                .inlineOnlyPreservingWhitespace))) ?? AttributedString(review.content))
                .multilineTextAlignment(.leading)
                .font(.callout.leading(.loose))
                .lineLimit(6)
                .padding(.bottom, 4)

            HStack {
                CourseTagView {
                    Text(course.teachers)
                }
                CourseTagView {
                    Text(course.formattedSemester)
                }
                Spacer()
                Text(review.timeCreated.formatted(.relative(presentation: .named, unitsStyle: .wide)))
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
