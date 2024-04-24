import Foundation
import DanXiKit

extension Hole {
    var sensitive: Bool {
        for tag in tags {
            if tag.name.hasPrefix("*") {
                return true
            }
        }
        
        return false
    }
}
