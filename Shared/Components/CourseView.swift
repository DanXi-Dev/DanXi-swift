import SwiftUI

struct CourseView: View {
    let courseGroup: DKCourseGroup
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(String(format: "%.1f", courseGroup.courses[0].credit)) Credit")
                .tagStyle(color: .accentColor)
            
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

struct CourseView_Previews: PreviewProvider {
    static var previews: some View {
        CourseView(courseGroup: PreviewDecode.decodeObj(name: "course")!)
    }
}
