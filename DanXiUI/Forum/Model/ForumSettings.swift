import SwiftUI
import Utils

public class ForumSettings: ObservableObject {
    public static let shared = ForumSettings()

    @AppStorage("sensitive-content") public var foldedContent = SensitiveContentSetting.fold
    @AppStorage("blocked-tags") public var blockedTags: [String] = []
    @AppStorage("blocked-holes") public var blockedHoles: [Int] = []
    @AppStorage("hidden-my-holes") public var hiddenMyHoles: [Int] = []
    @AppStorage("hidden-my-replies") public var hiddenMyReplies: [Int] = []
    @AppStorage("screenshot-alert") public var screenshotAlert = true
    @AppStorage("show-activity") public var showBanners = true
    @AppStorage("in-app-browser") var inAppBrowser = true
    @AppStorage("is-demo") var isDemo = false
    @AppStorage("watermark-opacity") public var watermarkOpacity = 0.010
    @AppStorage("preview-feature-setting") public var previewFeatureSetting = PreviewFeatureSetting.show

    public enum SensitiveContentSetting: Int {
        case fold = 1, show, hide
        
        static func from(description: String) -> Self {
            switch description {
            case "fold": .fold
            case "hide": .hide
            case "show": .show
            default: .fold
            }
        }
    }
    
    public enum PreviewFeatureSetting: Int {
        case hide = 1, show, focus
    }
}
