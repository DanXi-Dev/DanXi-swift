import Foundation
import SwiftUI


/// Pick a random color based on a name, used in tags & username color rendering.
func randomColor(_ name: String) -> Color {
    let randomColorList = [
        Color.red,
        Color.pink,
        Color.purple,
        Color.blue,
        Color.cyan,
        Color.teal,
        Color.green,
        Color.orange,
        Color.brown,
    ]
    
    if name.starts(with: "*") { // folding tags
        return Color.red
    }
    
    var sum = 0
    for c in name.utf16 {
        sum += Int(c)
    }
    sum %= randomColorList.count
    return randomColorList[sum]
}
