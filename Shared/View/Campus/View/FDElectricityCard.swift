import SwiftUI

struct FDElectricityCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Image(systemName: "powercord.fill")
                    Text("Dorm Electricity")
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.green)
                
                Spacer()
                
                AsyncContentView {
                    return try await FDElectricityAPI.getDormInfo()
                } content: { info in
                    VStack(alignment: .leading) {
                        Text(info.campus + info.building + info.roomNo)
                            .foregroundColor(.secondary)
                            .bold()
                            .font(.caption)
                        
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
                } loadingView: {
                    AnyView(
                        VStack(alignment: .leading) {
                            Text("")
                                .foregroundColor(.secondary)
                                .bold()
                                .font(.caption)
                            
                            HStack(alignment: .bottom) {
                                Text("--.--")
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
                    )
                } failureView: { error, retryHandler in
                    let errorDescription = (error as? LocalizedError)?.errorDescription ?? "Loading Failed"
                    return AnyView(
                        Button(action: retryHandler) {
                            Label(errorDescription, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 15))
                        }
                            .padding(.bottom, 15)
                    )
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
    }
}

#Preview {
    List {
        FDElectricityCard()
            .frame(height: 85)
    }
}
