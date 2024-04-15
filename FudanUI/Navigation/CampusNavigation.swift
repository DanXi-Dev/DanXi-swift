import SwiftUI
import FudanKit
import ViewUtils

struct CampusNavigation<Label: View>: View {
    @EnvironmentObject private var navigator: AppNavigator
    let label: () -> Label
    
    var body: some View {
        label()
            .navigationDestination(for: CampusSection.self) { section in
                section.destination
                    .environmentObject(navigator)
            }
            .navigationDestination(for: Playground.self) { playground in
                PlaygroundPage(playground)
                    .environmentObject(navigator)
            }
    }
}

public struct CampusContent: View {
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    func appendContent(value: any Hashable) {
        path.append(value)
    }
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
            CampusNavigation {
                CampusHome()
            }
        }
        .onReceive(navigator.contentSubject) { value in
            appendContent(value: value)
        }
    }
}

public struct CampusDetail: View {
    @EnvironmentObject private var navigator: AppNavigator
    @State private var path = NavigationPath()
    
    func appendDetail(item: any Hashable, replace: Bool) {
        if replace {
            path.removeLast(path.count)
        }
        path.append(item)
    }
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
            CampusNavigation {
                Image(systemName: "square.stack")
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

