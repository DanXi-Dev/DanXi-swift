import Foundation

class Preference: ObservableObject {
    static let shared = Preference()
    
    private let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
    
    init() {
        nlModelDebuggingMode = defaults?.bool(forKey: "nl-model-debugging-mode") ?? false
        let nsfwPreferenceRaw = defaults?.integer(forKey: "nsfw-preference") ?? 0
        nsfwSetting = NSFWPreference(rawValue: nsfwPreferenceRaw) ?? .fold
        showLastFloor = defaults?.bool(forKey: "show-last-floor") ?? true
        
        // TODO: init blocked tags
    }
    
    @Published var nlModelDebuggingMode: Bool = false {
        didSet {
            defaults?.setValue(nlModelDebuggingMode, forKey: "nl-model-debugging-mode")
        }
    }
    
    @Published var nsfwSetting = NSFWPreference.hide {
        didSet {
            defaults?.setValue(nsfwSetting.rawValue, forKey: "nsfw-preference")
        }
    }
    
    @Published var showLastFloor: Bool = false {
        didSet {
            defaults?.setValue(showLastFloor, forKey: "show-last-floor")
        }
    }
    
    @Published var blockedTags: Set<String> = []
}

enum NSFWPreference: Int {
    case fold
    case show
    case hide
}
