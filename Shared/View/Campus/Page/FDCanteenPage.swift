import SwiftUI
import FudanKit

struct FDCanteenPage: View {
    var body: some View {
        AsyncContentView {
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
            .navigationTitle("Canteen Popularity")
            .navigationBarTitleDisplayMode(.inline)
        }
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
                    CircularProgressView(progress: Double(room.current) / Double(room.capacity))
                    Text("\(room.current) / \(room.capacity)")
                        .font(.footnote)
                }
                .frame(minWidth: 50) // for alignment
            }
        }
    }
}
