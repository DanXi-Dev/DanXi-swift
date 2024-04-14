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

public struct CampusDetail: View {
    public init() {
        
    }
    
    public var body: some View {
        CampusNavigation {
            Image(systemName: "square.stack")
                .symbolVariant(.fill)
                .foregroundStyle(.tertiary)
                .font(.system(size: 60))
        }
    }
}

