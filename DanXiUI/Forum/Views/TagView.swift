import SwiftUI
import ViewUtils

struct TagView: View {
    @Environment(\.colorScheme) private var colorScheme
    private let name: String
    private let color: Color
    private let deletable: Bool
    
    init(_ name: String, color: Color? = nil, deletable: Bool = false) {
        self.name = name
        self.color = color ?? randomColor(name)
        self.deletable = deletable
    }
    
    var body: some View {
        HStack {
            Text(name)
            if deletable {
                Divider()
                Image(systemName: "multiply")
                    .imageScale(.small)
            }
        }
        .textCase(nil)
        .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
        .background(color.opacity(colorScheme == .light ? 0.1 : 0.2))
        .cornerRadius(5)
        .foregroundColor(color)
        .font(.caption2)
        .lineLimit(1)
    }
}
