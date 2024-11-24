import SwiftUI
import DanXiKit

struct ReturnCapsule: View {
    @EnvironmentObject var model: HoleModel
    let originalFloor: FloorPresentation
    @State private var currentSleepingTask: Task<Void, Never>? = nil
    
    var body: some View {
        HStack {
            VStack {
                Text("Return to Floor", bundle: .module)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(verbatim: "\(originalFloor.storey)F")
                    .foregroundStyle(.gray)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 2)
        }
        .padding(.horizontal, 44)
        .overlay(alignment: .leading) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .padding(.leading, 10)
        }
        
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(.thickMaterial)
                .shadow(.drop(radius: 12))
                
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onChange(of: model.targetFloorVisibility, perform: { visible in
            if !visible {
                Task {
                    if let existingTask = currentSleepingTask {
                            existingTask.cancel()
                    }
                    currentSleepingTask = Task {
                        try? await Task.sleep(for: .seconds(1))
                    }
                    _ = await currentSleepingTask?.result
                    withAnimation {
                        model.scrollFrom = nil
                        model.targetFloorId = nil
                        model.targetFloorVisibility = true
                    }
                }
            }
        })
        .onTapGesture {
            withAnimation {
                model.scrollTo(floorId: originalFloor.floor.id)
                model.scrollFrom = nil
                model.targetFloorId = nil
                model.targetFloorVisibility = true
            }
        }
    }
}

#Preview {
    let hole: Hole = decodePreviewData(filename: "hole", directory: "forum")
    let floor: Floor = decodePreviewData(filename: "floor", directory: "forum")
    let presentation = FloorPresentation(floor: floor, storey: 5)
    let floors: [Floor] = decodePreviewData(filename: "floors", directory: "forum")
    let model = HoleModel(hole: hole, floors: floors)
    
    ReturnCapsule(originalFloor: presentation)
        .environmentObject(model)
}
