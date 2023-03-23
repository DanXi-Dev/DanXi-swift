import SwiftUI

struct THSimpleFloor: View {
    let floor: THFloor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            THPosterView(name: floor.posterName, isPoster: false)
            MarkdownView(floor.content)
            bottom
        }
    }
    
    var bottom: some View {
        HStack {
            Text("##\(String(floor.id))")
            Spacer()
            Text(floor.createTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
        }
        .font(.caption)
        .foregroundColor(.separator)
    }
}
