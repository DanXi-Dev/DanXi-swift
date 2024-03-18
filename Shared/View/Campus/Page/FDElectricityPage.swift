import SwiftUI

struct FDElectricityPage: View {
    var body: some View {
        AsyncContentView {
            return try await FDElectricityAPI.getDormInfo()
        } content: { info in
            List {
                LabeledContent {
                    Text(info.campus)
                } label: {
                    Text("Campus")
                }
                
                LabeledContent {
                    Text(info.building + info.roomNo)
                } label: {
                    Text("Dorm")
                }
                
                LabeledContent {
                    Text("\(String(info.availableElectricity)) kWh")
                } label: {
                    Text("Electricity Available")
                }
                
                LabeledContent {
                    Text("\(String(info.usedElectricity)) kWh")
                } label: {
                    Text("Electricity Used")
                }
            }
            .navigationTitle("Dorm Electricity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
