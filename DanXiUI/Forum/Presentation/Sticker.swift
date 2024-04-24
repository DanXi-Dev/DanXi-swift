import SwiftUI

enum Sticker: String, CaseIterable {
    case angry = "dx_angry"
    case call = "dx_call"
    case cate = "dx_cate"
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
        case .angry: Image("Angry")
        case .call: Image("Call")
        case .cate: Image("Cate")
        case .egg: Image("Egg")
        case .fright: Image("Fright")
        case .heart: Image("Heart")
        case .hug: Image("Hug")
        case .overwhelm: Image("Overwhelm")
        case .roll: Image("Roll")
        case .roped: Image("Roped")
        case .sleep: Image("Sleep")
        case .swim: Image("Swim")
        case .thrill: Image("Thrill")
        case .touchFish: Image("Touch Fish")
        case .twin: Image("Twin")
        }
    }
}
