import SwiftUI
import FudanKit

struct FDElectricityPage: View {
    var body: some View {
        AsyncContentView {
            return try await ElectricityStore.shared.getCachedElectricityUsage()
        } content: { info in
            List {
                LabeledContent {
                    Text(info.campus)
                } label: {
                    Text("Campus")
                }
                
                LabeledContent {
                    Text(info.building + info.room)
                } label: {
                    Text("Dorm")
                }
                
                LabeledContent {
                    Text("\(String(info.electricityAvailable)) kWh")
                } label: {
                    Text("Electricity Available")
                }
                
                LabeledContent {
                    Text("\(String(info.electricityUsed)) kWh")
                } label: {
                    Text("Electricity Used")
                }
            }
            .navigationTitle("Dorm Electricity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
