import SwiftUI

enum Sticker: String, CaseIterable {
    case angry = "dx_angry"
    case call = "dx_call"
    case cate = "dx_cate"
    case dying = "dx_dying"
    case egg = "dx_egg"
    case fright = "dx_fright"
    case heart = "dx_heart"
    case hug = "dx_hug"
    case overwhelm = "dx_overwhelm"
    case roll = "dx_roll"
    case roped = "dx_roped"
    case sleep = "dx_sleep"
    case swim = "dx_swim"
    case thrill = "dx_thrill"
    case touchFish = "dx_touch_fish"
    case twin = "dx_twin"
    
    var image: Image {
        switch self {
        case .angry: Image("angry", bundle: .module)
        case .call: Image("alarm", bundle: .module)
        case .cate: Image("cat", bundle: .module)
        case .dying: Image("dying", bundle: .module)
        case .egg: Image("shield", bundle: .module)
        case .fright: Image("scared", bundle: .module)
        case .heart: Image("flipped", bundle: .module)
        case .hug: Image("hug", bundle: .module)
        case .overwhelm: Image("broken", bundle: .module)
        case .roll: Image("roll", bundle: .module)
        case .roped: Image("hung", bundle: .module)
        case .sleep: Image("asleep", bundle: .module)
        case .swim: Image("swimming", bundle: .module)
        case .thrill: Image("happy", bundle: .module)
        case .touchFish: Image("slacking", bundle: .module)
        case .twin: Image("dd", bundle: .module)
        }
    }
}
