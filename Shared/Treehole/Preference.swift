import Foundation

class Preference: ObservableObject {
    static let shared = Preference()
    
    private let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
    
    init() {
        nlModelDebuggingMode = defaults?.bool(forKey: "nl-model-debugging-mode") ?? false
        let nsfwPreferenceRaw = defaults?.integer(forKey: "nsfw-preference") ?? 0
        nsfwSetting = NSFWPreference(rawValue: nsfwPreferenceRaw) ?? .fold
        showLastFloor = defaults?.bool(forKey: "show-last-floor") ?? true
        
        if let data = defaults?.data(forKey: "blocked-tags") {
            do {
                blockedTags = try JSONDecoder().decode([THTag].self, from: data)
            } catch {
                blockedTags = []
            }
        }
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
    
    @Published var blockedTags: [THTag] = [] {
        didSet {
            do {
                let data = try JSONEncoder().encode(blockedTags)
                defaults?.setValue(data, forKey: "blocked-tags")
            } catch {
                
            }
        }
    }
}

enum NSFWPreference: Int {
    case fold
    case show
    case hide
}
