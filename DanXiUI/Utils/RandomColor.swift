import SwiftUI

/// Pick a random color based on a name, used in tags & username color rendering.
func randomColor(_ name: String) -> Color {
    let hashColorList = [
        Color.red,
        Color.pink,
        Color.purple,
        Color("danxi deep purple", bundle: .module),
        Color("danxi indigo", bundle: .module),
        Color.blue,
        Color("danxi light blue", bundle: .module),
        Color.cyan,
        Color.teal,
        Color.green,
        Color("danxi light green", bundle: .module),
        Color("danxi lime", bundle: .module),
        Color("danxi yellow", bundle: .module),
        Color("danxi amber", bundle: .module),
        Color.orange,
        Color("danxi deep orange", bundle: .module),
        Color.brown,
        Color("danxi blue grey", bundle: .module),
        Color("danxi grey", bundle: .module)
    ]
    
    if name.starts(with: "*") { // folding tags
        return Color.red
    }
    
    var sum = 0
    for c in name.utf16 {
        sum += Int(c)
    }
    sum %= hashColorList.count
    return hashColorList[sum]
}
