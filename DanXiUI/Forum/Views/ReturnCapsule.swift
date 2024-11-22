import SwiftUI

struct ReturnCapsule: View {
    @EnvironmentObject var model: HoleModel
    let originalFloor: FloorPresentation
    @State private var currentSleepingTask: Task<Void, Never>? = nil
    
    var body: some View {
        HStack {
            VStack {
                Text("Return to Floor")
                    .font(.caption)
                    .fontWeight(.bold)
                Text(verbatim: "\(originalFloor.storey)F")
                    .foregroundStyle(.gray)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 2)
        }
        .padding(.horizontal, 40)
        .overlay(alignment: .leading) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)
                .padding(.leading, 10)
        }
        
        .padding(.vertical, 7)
        .background {
            Capsule(style: .continuous)
                .fill(.background)
                .shadow(.drop(radius: 12))
                
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task {
            if let existingTask = currentSleepingTask {
                    existingTask.cancel()
            }
            currentSleepingTask = Task {
                try? await Task.sleep(for: .seconds(8))
            }
            _ = await currentSleepingTask?.result
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
