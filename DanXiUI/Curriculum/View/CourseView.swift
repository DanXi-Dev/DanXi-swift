import SwiftUI
import DanXiKit

struct CourseView: View {
    let courseGroup: CourseGroup
    
    var body: some View {
        VStack(alignment: .leading) {
            CourseTagView {
                Text("\(String(format: "%.1f", courseGroup.courses[0].credit)) Credit", bundle: .module)
            }
            
            Text(courseGroup.name)
                .bold()
                .font(.title2)
                .padding(.bottom, 1.0)
            
            Text(verbatim: "\(courseGroup.department) - \(courseGroup.code)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
}
