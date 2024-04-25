import SwiftUI

public struct FormTitle: View {
    public let title: LocalizedStringKey
    public let description: LocalizedStringKey
    
    public init(title: LocalizedStringKey, description: LocalizedStringKey) {
        self.title = title
        self.description = description
    }
    
    public var body: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    Text(title)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                    Text(description)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}
