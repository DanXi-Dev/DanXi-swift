import SwiftUI
import ViewUtils

struct HighlightTagView: View {
    @Environment(\.colorScheme) private var colorScheme
    private let name: String
    private let deletable: Bool
    
    init(_ name: String, deletable: Bool = false) {
        self.name = name
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
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color("danxi light blue", bundle: .module)]),
                                   startPoint: .leading,
                                   endPoint: .trailing)
                    .ignoresSafeArea())
        .cornerRadius(5)
        .foregroundColor(.white)
        .font(.caption2)
        .lineLimit(1)
    }
}
