import SwiftUI
import ViewUtils

struct THMyReplyPage: View {
    var body: some View {
        THBackgroundList {
            AsyncCollection { floors in
                try await THRequests.loadMyFloor(offset: floors.count)
            } content: { floor in
                Section {
                    NavigationListRow(value: THHoleLoader(floor)) {
                        THSimpleFloor(floor: floor)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                }
            }
        }
        .sectionSpacing(10)
        .navigationTitle("My Reply")
    }
}
