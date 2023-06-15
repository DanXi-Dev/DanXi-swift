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
                    Label("Campus", systemImage: "building.fill")
                }
                
                LabeledContent {
                    Text(info.building + info.roomNo)
                } label: {
                    Label("Dorm", systemImage: "bed.double.fill")
                }
                
                LabeledContent {
                    Text("\(String(info.availableElectricity)) kWh")
                } label: {
                    Label("Electricity Available", systemImage: "minus.plus.and.fluid.batteryblock")
                }
                
                LabeledContent {
                    Text("\(String(info.usedElectricity)) kWh")
                } label: {
                    Label("Electricity Used", systemImage: "minus.plus.batteryblock.stack")
                }
            }
            .navigationTitle("Dorm Electricity")
        }
    }
}
