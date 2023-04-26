import SwiftUI

struct DKCourseView: View {
    let courseGroup: DKCourseGroup
    
    var body: some View {
        VStack(alignment: .leading) {
            DKTagView {
                Text("\(String(format: "%.1f", courseGroup.courses[0].credit)) Credit")
            }
            
            Text(courseGroup.name)
                .bold()
                .font(.title2)
                .padding(.bottom, 1.0)
            
            Text("\(courseGroup.department) - \(courseGroup.code)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
}
