import SwiftUI

struct HistoryList: View {
    @Binding var floor: THFloor
    
    @State var histories: [THHistory] = []
    
    @State var showRestoreSheet = false
    @State var historyId: Int? = nil
    @State var restoreReason = ""
    @State var showRestoreError = false
    @State var restoreErrorInfo = ""
    
    func restoreFloor() async throws {
        guard let historyId = historyId else {
            return
        }
        
        floor = try await TreeholeRequests.restoreFloor(floorId: floor.id,
                                                         historyId: historyId,
                                                         restoreReason: restoreReason)
    }
    
    var body: some View {
        NavigationView {
            LoadingView {
                histories = try await TreeholeRequests.loadFloorHistory(floorId: floor.id)
            } content: {
                List {
                    ForEach(histories) { history in
                        VStack(alignment: .leading, spacing: 10) {
                            if !history.reason.isEmpty {
                                Text("Edit reason: \(history.reason)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            
                            MarkdownView(history.content)
                            
                            HStack {
                                Text(history.updateTime.formatted())
                                Spacer()
                                Text("User: \(String(history.userId))")
                            }
                            .foregroundColor(.secondary)
                            .font(.caption)
                        }
                        .swipeActions {
                            Button {
                                self.historyId = history.id
                                showRestoreSheet = true
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showRestoreSheet) {
                    restoreForm
                }
            }
                        .navigationTitle("Edit History")
                        .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var restoreForm: some View {
        FormPrimitive(title: "Restore History",
                      allowSubmit: true,
                      errorTitle: "Restore Failed") {
            Section {
                TextField("Restore reason", text: $restoreReason)
            }
        } action: {
            try await restoreFloor()
        }
    }
}
