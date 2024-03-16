import SwiftUI

struct THMyReplyPage: View {
    var body: some View {
        THBackgroundList {
            AsyncCollection { floors in
                try await THRequests.loadMyFloor(offset: floors.count)
            } content: { floor in
                NavigationListRow(value: THHoleLoader(floor)) {
                    THSimpleFloor(floor: floor)
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("My Reply")
    }
}
