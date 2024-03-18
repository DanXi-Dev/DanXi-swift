import SwiftUI

struct FDElectricityCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Image(systemName: "powercord")
                    Text("Dorm Electricity")
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.green)
                
                Spacer()
                
                AsyncContentView(style: .widget) {
                    return try await FDElectricityAPI.getDormInfo()
                } content: { info in
                    HStack(alignment: .bottom) {
                        Text(String(info.availableElectricity))
                            .bold()
                            .font(.system(size: 25, design: .rounded))
                        +
                        Text("kWh")
                            .foregroundColor(.secondary)
                            .bold()
                            .font(.callout)
                        
                        Spacer()
                    }
                }
                
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
        .frame(height: 100)
    }
}

#Preview {
    List {
        FDElectricityCard()
    }
}
