import SwiftUI
import Introspect

struct TestView: View {
    var body: some View {
        TextEditor(text: .constant("Hello this is a text editor"))
            .introspectTextView { tv in
                tv.isEditable = false
                tv.selectAll(nil)
            }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
