import SwiftUI
import DanXiKit

struct SimpleFloorView: View {
    let floor: Floor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            PosterView(name: floor.anonyname, isPoster: false)
            Text(floor.content.inlineAttributed())
                .font(.callout)
                .foregroundColor(floor.deleted ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
            bottom
        }
        .listRowInsets(EdgeInsets(top: 11, leading: 11, bottom: 11, trailing: 11))
    }
    
    private var bottom: some View {
        HStack {
            Text(verbatim: "##\(String(floor.id))")
            Spacer()
            Text(floor.timeCreated.autoFormatted())
        }
        .font(.caption)
        .foregroundColor(.separator)
    }
}
