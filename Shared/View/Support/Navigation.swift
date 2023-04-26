import SwiftUI

struct NavigationListRow<P: Hashable, Label: View>: View {
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
