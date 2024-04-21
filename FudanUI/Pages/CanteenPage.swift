import SwiftUI
import FudanKit
import ViewUtils

struct CanteenPage: View {
    init() { }
    
    var body: some View {
        AsyncContentView { _ in
            return try await CanteenAPI.getCanteenQueuing()
        } content: { canteens in
            List(canteens) { canteen in
                Section(canteen.campus) {
                    ForEach(canteen.diningRooms) { room in
                        CanteenRow(room: room)
                    }
                }
                .headerProminence(.increased)
            }
            .listStyle(SidebarListStyle()) // support fold section
        }
        .navigationTitle("Canteen Popularity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct CanteenRow: View {
    let room: DiningRoom
    
    var body: some View {
        VStack {
            HStack() {
                Text(room.name)
                
                Spacer()
                
                VStack {
                    CircularProgressView(value: room.current, total: room.capacity)
                    Text("\(room.current) / \(room.capacity)")
                        .font(.footnote)
                }
                .frame(minWidth: 50) // for alignment
            }
        }
    }
}
