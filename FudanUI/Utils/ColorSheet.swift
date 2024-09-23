import SwiftUI

enum ThemeColor: Int, Codable, CaseIterable, Identifiable, Hashable {
    case none = 0
    case pink
    case red
    case orange
    case green
    case cyan
    case blue
    case indigo
    
    var id: Int {
        self.rawValue
    }
    
    var color: Color? {
        switch self {
        case .none: nil
        case .pink: Color.pink
        case .red: Color.red
        case .orange: Color.orange
        case .green: Color.green
        case .cyan: Color.cyan
        case .blue: Color.blue
        case .indigo: Color.indigo
        }
    }
    
    @ViewBuilder
    var label: some View {
        switch self {
        case .none:
            HStack {
                Image(systemName: "circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.gray.opacity(0.3))
                Text("Colorful", bundle: .module)
            }
        case .pink:
            HStack {
                Image(systemName: "circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.pink)
                Text("Pink", bundle: .module)
            }
        case .red:
            HStack {
                Image(systemName: "circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                Text("Red", bundle: .module)
            }
        case .orange:
            HStack {
                Image(systemName: "circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                Text("Orange", bundle: .module)
            }
        case .green:
            HStack {
                Image(systemName: "circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
                Text("Green", bundle: .module)
            }
        case .cyan:
            HStack {
                Image(systemName: "circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.cyan)
                Text("Cyan", bundle: .module)
            }
        case .blue:
            HStack {
                Image(systemName: "circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.blue)
                Text("Blue", bundle: .module)
            }
        case .indigo:
            HStack {
                Image(systemName: "circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.indigo)
                Text("Indigo", bundle: .module)
            }
        }
        
    }
}

struct ColorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var themeColor: ThemeColor
    
    var body: some View {
        NavigationStack {
            List {
                Picker(String(""), selection: $themeColor) {
                    ForEach(ThemeColor.allCases) { color in
                        color.label
                            .tag(color)
                    }
                }
                .pickerStyle(.inline)
                
            }
            .navigationTitle(String(localized: "Change Color", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Text("Done", bundle: .module)
                }
            }
        }
    }
}
