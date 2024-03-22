import SwiftUI

struct FDCanteenPage: View {
    var body: some View {
        AsyncContentView {
            return try await FDCanteenAPI.getCanteenInfo()
        } content: { canteens in
            List(canteens) { canteen in
                Section(canteen.campus) {
                    ForEach(canteen.diningRooms) { room in
                        CanteenRow(room: room)
                    }
                }
                .headerProminence(.increased)
            }
            .listStyle(.sidebar) // support fold section
            .navigationTitle("Canteen Popularity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

fileprivate struct CanteenRow: View {
    let room: FDDiningRoom
    
    var body: some View {
        VStack {
            HStack() {
                Text(room.name)
                
                Spacer()
                
                Text("\(room.current) / \(room.capacity)")
                    .font(.footnote)
            }
            
            ProgressView(value: Double(room.current), total: Double(room.capacity))
        }
    }
}
