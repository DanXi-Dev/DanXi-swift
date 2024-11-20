import SwiftUI

struct ReturnCapsule: View {
    @EnvironmentObject var model: HoleModel
    let originalFloor: FloorPresentation
    
    var body: some View {
        HStack {
            VStack {
                Text("Return to Floor")
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(verbatim: "\(originalFloor.storey)F")
                    .foregroundStyle(.gray.opacity(0.5))
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 40)
        .overlay(alignment: .leading) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.blue.opacity(0.6))
                .padding(.leading, 10)
        }
        
        .padding(.vertical, 7)
        .background {
            Capsule(style: .continuous)
                .fill(.regularMaterial)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(8))
            withAnimation {
                model.scrollFrom = nil
            }
        }
        .onTapGesture {
            withAnimation {
                model.scrollTo(floorId: originalFloor.floor.id)
                model.scrollFrom = nil
            }
        }
    }
}
