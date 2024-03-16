import SwiftUI

struct FDElectricityCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Image(systemName: "battery.100percent")
                    Text("Dorm Electricity")
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.green)
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    Text("314.15")
                        .bold()
                        .font(.system(size: 25, design: .rounded))
                    +
                    Text("kWh")
                        .foregroundColor(.secondary)
                        .bold()
                        .font(.callout)
                    
                    Spacer()
                    
                    Image(systemName: "battery.75")
                        .font(.title)
                        .foregroundStyle(.yellow)
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
