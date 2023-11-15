import SwiftUI

struct THModeratePage: View {
    @Environment(\.editMode) private var editMode
    @StateObject private var model = THModerateModel()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List(selection: $model.selectedItems) {
                AsyncCollection(model.items,
                                endReached: model.endReached,
                                action: model.loadMore) { item in
                    VStack(alignment: .leading) {
                        Text(item.content)
                        HStack {
                            Text("##\(String(item.id))")
                            Spacer()
                            Text(item.createTime.formatted())
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }
                    .tag(item)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Moderate")
            .toolbar {
                EditButton()
            }
            
            HStack(spacing: 30) {
                if !model.selectedItems.isEmpty {
                    AsyncButton {
                        await model.setSelected(sensitive: false)
                        editMode?.wrappedValue = .inactive
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    
                    AsyncButton {
                        await model.setSelected(sensitive: true)
                        editMode?.wrappedValue = .inactive
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.init(top: 0, leading: 0, bottom: 45, trailing: 30))
            .font(.largeTitle)
        }
    }
}


@MainActor
class THModerateModel: ObservableObject {
    @Published var items: [THSensitiveEntry] = []
    @Published var selectedItems: Set<THSensitiveEntry> = []
    @Published var endReached = false
    
    func loadMore() async throws {
        let newItems = try await THRequests.listSensitive(startTime: items.last?.createTime.ISO8601Format())
        let currentIds = items.map(\.id)
        let inserteditems = newItems.filter { !currentIds.contains($0.id) }
        items += inserteditems
        endReached = inserteditems.isEmpty
    }
    
    func removeSelected() {
        let ids = selectedItems.map(\.id)
        withAnimation {
            items = items.filter { !ids.contains($0.id) }
        }
    }
    
    func setSelected(sensitive: Bool) async {
        let ids = selectedItems.map(\.id)
        var successIds: [Int] = []
        for id in ids {
            do {
                try await THRequests.setSensitive(id: id, sensitive: sensitive)
                successIds.append(id)
            } catch {
                print(error)
            }
        }
        
        withAnimation {
            items = items.filter { !successIds.contains($0.id) }
        }
    }
    
    
}

#Preview {
    NavigationStack {
        THModeratePage()
    }
}
