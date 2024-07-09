import SwiftUI

public struct FormTitle: View {
    private let title: Text
    private let description: Text
    
    public init(title: String, description: String) {
        self.title = Text(title)
        self.description = Text(description)
    }
    
    public init(title: String, description: AttributedString) {
        self.title = Text(title)
        self.description = Text(description)
    }
    
    public var body: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    title
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                    description
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}
