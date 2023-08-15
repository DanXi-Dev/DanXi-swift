import SwiftUI

struct FormTitle: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    
    var body: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    Text(title)
                        .font(.title)
                        .bold()
                    Text(description)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}
