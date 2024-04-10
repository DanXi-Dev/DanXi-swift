import SwiftUI
import MarkdownUI

// TODO: finish this
public struct CustomMarkdown: View {
    
    public init(_ content: String) {
        self.content = content
    }
    
    let content: String
    
    public var body: some View {
        Text(content)
    }
}
