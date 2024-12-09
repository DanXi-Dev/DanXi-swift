import SwiftUI
import DanXiUI
import ViewUtils
import Utils

enum SettingsSection: Hashable {
    case about
    case credit
    case debug
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .about:
            AboutPage()
        case .credit:
            CreditPage()
        case .debug:
            DebugPage()
        }
    }
}

struct SettingsNavigation<Label: View>: View {
    @EnvironmentObject private var navigator: AppNavigator
    let label: () -> Label
    
    var body: some View {
        label()
            .navigationDestination(for: SettingsSection.self) { section in
                section.destination
            }
            .navigationDestination(for: DanXiUI.ForumSettingsSection.self) { section in
                section.destination
            }
    }
}

struct SettingsContent: View {
    @EnvironmentObject private var tabViewModel: TabViewModel
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    func appendContent(value: any Hashable) {
        path.append(value)
    }
    
    func appendDetail(value: any Hashable) {
        path.append(value)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            SettingsNavigation {
                SettingsPage()
            }
        }
        .onReceive(navigator.contentSubject) { value in
            appendContent(value: value)
        }
        .onReceive(navigator.detailSubject) { value, _ in
            if navigator.isCompactMode {
                appendDetail(value: value)
            }
        }
        .onReceive(tabViewModel.navigationControl) { _ in
            if path.isEmpty {
                tabViewModel.scrollControl.send()
            } else {
                path.removeLast(path.count)
            }
        }
    }
}

struct SettingsDetail: View {
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    func appendDetail(item: any Hashable, replace: Bool) {
        if replace {
            path.removeLast(path.count)
        }
        path.append(item)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            SettingsNavigation {
                Image(systemName: "gearshape")
                    .symbolVariant(.fill)
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 60))
            }
        }
        .onReceive(navigator.detailSubject) { item, replace in
            appendDetail(item: item, replace: replace)
        }
    }
}
