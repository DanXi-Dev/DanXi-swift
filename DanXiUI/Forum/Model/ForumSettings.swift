import SwiftUI
import Utils

public class ForumSettings: ObservableObject {
    public static let shared = ForumSettings()

    @AppStorage("sensitive-content") public var sensitiveContent = SensitiveContentSetting.fold
    @AppStorage("blocked-tags") public var blockedTags: [String] = []
    @AppStorage("blocked-holes") public var blockedHoles: [Int] = []
    @AppStorage("screenshot-alert") public var screenshotAlert = true
    @AppStorage("show-activity") public var showBanners = true
    @AppStorage("is-reviewer") var isReviewer = false
    @AppStorage("watermark-opacity") public var watermarkOpacity = 0.010

    public enum SensitiveContentSetting: Int {
        case fold = 1, show, hide
    }
}
