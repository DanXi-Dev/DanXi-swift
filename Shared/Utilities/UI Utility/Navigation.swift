import SwiftUI

struct NavigationPlainLink<P: Hashable, Label: View>: View {
    let value: P
    let label: Label
    
    init(value: P, label: () -> Label) {
        self.value = value
        self.label = label()
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            NavigationLink(value: value) {
                EmptyView()
            }
                .opacity(0)
                .buttonStyle(.plain)
            
            label
        }
    }
}

class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
}
