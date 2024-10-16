import SwiftUI
import FudanKit
import ViewUtils

struct CanteenPage: View {
    init() { }
    
    var body: some View {
        AsyncContentView {
            try await CanteenAPI.getCanteenQueuing()
        } content: { canteens in
            CanteenPageContent(canteens: canteens)
        }
        .navigationTitle(String(localized: "Canteen Popularity", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CanteenPageContent: View {
    let canteens: [Canteen]
    
    var body: some View {
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
                    Text(verbatim: "\(room.current) / \(room.capacity)")
                        .font(.footnote)
                }
                .frame(minWidth: 50) // for alignment
            }
        }
    }
}

#Preview {
    let canteens: [Canteen] = decodePreviewData(filename: "canteen")
    NavigationStack {
        CanteenPageContent(canteens: canteens)
            .navigationTitle(String(localized: "Canteen Popularity", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
    }
}
