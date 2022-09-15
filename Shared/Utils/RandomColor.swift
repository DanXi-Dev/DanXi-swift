import Foundation
import SwiftUI


/// Pick a random color based on a name, used in tags & username color rendering.
func randomColor(_ name: String) -> Color {
    let randomColorList = [
        Color.red,
        Color.pink,
        Color.purple,
        Color("deep purple"),
        Color.indigo,
        Color.blue,
        Color("light blue"),
        Color.cyan,
        Color.teal,
        Color.green,
        Color("light green"),
        Color("lime"),
        Color.yellow,
        Color("amber"),
        Color.orange,
        Color("deep orange"),
        Color.brown,
        Color("blue grey"),
        Color.secondary // grey
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
