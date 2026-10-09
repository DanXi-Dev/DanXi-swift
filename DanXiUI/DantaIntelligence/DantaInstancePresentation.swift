import DanXiKit
import SwiftUI

extension DantaIntelligenceInstanceState {
    var displayName: String {
        switch self {
        case .notStarted:
            String(localized: "Not Set Up", bundle: .module)
        case .provisioning:
            String(localized: "Provisioning", bundle: .module)
        case .starting:
            String(localized: "Starting", bundle: .module)
        case .ready:
            String(localized: "Ready", bundle: .module)
        case .stopping:
            String(localized: "Stopping", bundle: .module)
        case .stopped:
            String(localized: "Stopped", bundle: .module)
        case .resetting:
            String(localized: "Resetting", bundle: .module)
        case .failed:
            String(localized: "Failed", bundle: .module)
        case .unknown:
            String(localized: "Unknown", bundle: .module)
        }
    }

    var symbolName: String {
        switch self {
        case .notStarted:
            "server.rack"
        case .provisioning, .starting, .stopping, .resetting:
            "arrow.trianglehead.2.clockwise.rotate.90"
        case .ready:
            "checkmark.circle.fill"
        case .stopped:
            "stop.circle.fill"
        case .failed:
            "exclamationmark.triangle.fill"
        case .unknown:
            "questionmark.circle"
        }
    }

    var tintColor: Color {
        switch self {
        case .ready:
            .green
        case .stopped, .stopping:
            .orange
        case .failed:
            .red
        case .notStarted, .provisioning, .starting, .resetting, .unknown:
            .accentColor
        }
    }


}
extension DantaIntelligenceLifecycleAction {
    var buttonTitle: String {
        switch self {
        case .start:
            String(localized: "Start Instance", bundle: .module)
        case .stop:
            String(localized: "Stop Instance", bundle: .module)
        case .restart:
            String(localized: "Restart Instance", bundle: .module)
        case .reset:
            String(localized: "Reset Instance", bundle: .module)
        }
    }

    var progressTitle: String {
        switch self {
        case .start:
            String(localized: "Starting instance…", bundle: .module)
        case .stop:
            String(localized: "Stopping instance…", bundle: .module)
        case .restart:
            String(localized: "Restarting instance…", bundle: .module)
        case .reset:
            String(localized: "Resetting instance…", bundle: .module)
        }
    }

    var symbolName: String {
        switch self {
        case .start:
            "play.fill"
        case .stop:
            "stop.fill"
        case .restart:
            "arrow.clockwise"
        case .reset:
            "trash"
        }
    }
}
