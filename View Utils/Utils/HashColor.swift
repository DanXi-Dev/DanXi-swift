import Foundation
import SwiftUI

/// Pick a random color based on a name, used in tags & username color rendering.
public func hashColorForTreehole(_ name: String) -> Color {
    let hashColorList = [
        Color.red,
        Color.pink,
        Color.purple,
        Color("danxi deep purple"),
        Color("danxi indigo"),
        Color.blue,
        Color("danxi light blue"),
        Color.cyan,
        Color.teal,
        Color.green,
        Color("danxi light green"),
        Color("danxi lime"),
        Color("danxi yellow"),
        Color("danxi amber"),
        Color.orange,
        Color("danxi deep orange"),
        Color.brown,
        Color("danxi blue grey"),
        Color("danxi grey")
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

public func hashColorForCalendar(_ name: String) -> Color {
    let hashColorList = [
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
    
    var sum = 0
    for c in name.utf16 {
        sum += Int(c)
    }
    sum %= hashColorList.count
    return hashColorList[sum]
}
