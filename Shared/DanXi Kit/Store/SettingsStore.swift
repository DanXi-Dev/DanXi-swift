import Foundation

class Preference: ObservableObject {
    static let shared = Preference()
    
    private let defaults = UserDefaults.standard
    
    init() {
        nlModelDebuggingMode = defaults.bool(forKey: "nl-model-debugging-mode")
        self.nsfwSetting = NSFWPreference(rawValue: defaults.integer(forKey: "nsfw-preference")) ?? .show
        showLastFloor = defaults.bool(forKey: "show-last-floor")
        
        if let data = defaults.data(forKey: "blocked-tags") {
            do {
                blockedTags = try JSONDecoder().decode([String].self, from: data)
            } catch {
                blockedTags = []
            }
        }
    }
    
    @Published var nlModelDebuggingMode: Bool = false {
        didSet {
            defaults.setValue(nlModelDebuggingMode, forKey: "nl-model-debugging-mode")
        }
    }
    
    @Published var nsfwSetting = NSFWPreference.show {
        didSet {
            defaults.setValue(nsfwSetting.rawValue, forKey: "nsfw-preference")
        }
    }
    
    @Published var showLastFloor: Bool = false {
        didSet {
            defaults.setValue(showLastFloor, forKey: "show-last-floor")
        }
    }
    
    @Published var blockedTags: [String] = [] {
        didSet {
            do {
                let data = try JSONEncoder().encode(blockedTags)
                defaults.setValue(data, forKey: "blocked-tags")
            } catch {
                
            }
        }
    }
}

enum NSFWPreference: Int {
    case fold = 1
    case show = 2
    case hide = 3
}
