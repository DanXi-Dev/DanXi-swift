import Foundation
import SwiftUI

let randomColorList = [
    Color.red,
    Color.pink,
    Color.purple,
    Color("deep purple"), // deep-purple, FIXME: not visible in dark mode
    Color.indigo,
    Color.blue,
    Color("light blue"), // light-blue
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


func randomColor(name: String) -> Color {
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
