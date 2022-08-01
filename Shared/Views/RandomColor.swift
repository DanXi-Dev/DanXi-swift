import Foundation
import SwiftUI

extension Color { // init color with hex value
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
    
    static let randomColorList = [
        Color.red,
        Color.pink,
        Color.purple,
        Color(hex: 0x673AB7), // deep-purple, FIXME: not visible in dark mode
        Color.indigo,
        Color.blue,
        Color(hex: 0x03A9F4), // light-blue
        Color.cyan,
        Color.teal,
        Color.green,
        Color(hex: 0x8BC34A), // light-greem
        Color(hex: 0x32CD32), // lime
        Color.yellow,
        Color(hex: 0xFFBF00), // amber
        Color.orange,
        Color(hex: 0xDD6E0F), // deep-orange
        Color.brown,
        Color(hex: 0x7393B3), // blue-grey
        Color.secondary // grey
    ]
}

func randomColor(name: String) -> Color {
    if name.starts(with: "*") { // folding tags
        return Color.red
    }
    
    var sum = 0
    for c in name.utf16 {
        sum += Int(c)
    }
    sum %= Color.randomColorList.count
    return Color.randomColorList[sum]
    
}
