import SwiftUI
import ViewUtils
import DanXiKit

struct SensitiveNoticeSheet: View {
    var body: some View {
        Sheet(String(localized: "SensitiveTitle", bundle: .module)) {
            // do nothing
        } content: {
            Section {
                Text("Test")
            }
        }
        .watermark()
    }
}
