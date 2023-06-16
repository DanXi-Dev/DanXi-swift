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
        }
    }
}

fileprivate struct CanteenRow: View {
    let room: FDDiningRoom
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(room.name)
                Text("\(room.current) / \(room.capacity)")
                    .foregroundColor(.secondary)
                    .font(.callout)
            }
            Spacer()
            
            let progress = room.current > room.capacity ? 1.0 : (Double(room.current) / Double(room.capacity))
            CircularProgressView(progress: progress)
        }
    }
}
