import SwiftUI

struct HistoryList: View {
    @Binding var floor: THFloor
    
    @State var histories: [THHistory] = []
    @State var loading = true
    @State var initFinished = false
    @State var loadingError = ""
    
    func loadHistory() async {
        do {
            histories = try await DXNetworks.shared.loadFloorHistory(floorId: floor.id)
            initFinished = true
        } catch {
            loadingError = error.localizedDescription
        }
    }
    
    var body: some View {
        NavigationView {
            LoadingView(loading: $loading,
                        finished: $initFinished,
                        errorDescription: loadingError,
                        action: loadHistory) {
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
                    }
                }
            }
                        .navigationTitle("Edit History")
                        .navigationBarTitleDisplayMode(.inline)
        }
    }
}
