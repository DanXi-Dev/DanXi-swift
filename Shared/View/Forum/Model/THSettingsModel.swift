import SwiftUI

@MainActor
class THSettings: ObservableObject {
    static let shared = THSettings()
    
    private init() {
        
    }
    
    enum SensitiveContentSetting: Int {
        case fold = 1, show, hide
    }
    
    @AppStorage("sensitive-content") var sensitiveContent = SensitiveContentSetting.fold
    @AppStorage("blocked-tags") var blockedTags: [String] = []
    @AppStorage("show-last-floor") var showLastFloor: Bool = false
    @AppStorage("blocked-holes") var blockedHoles: [Int] = []
}
