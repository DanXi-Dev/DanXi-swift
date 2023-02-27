import SwiftUI

struct FDEcardPage: View {
    @State var balance = ""
    @State var page = 1
    @State var records: [FDTradeRecord] = []
    
    @State var endReached = false
    @State var recordLoading = false
    @State var recordError = ""
    
    func initialFetch() async throws {
        balance = try await FDEcardRequests.getEcardBalance()
        try await FDEcardRequests.getCSRF()
        await loadMoreRecords()
    }
    
    func loadMoreRecords() async {
        do {
            recordLoading = true
            defer { recordLoading = false }
            let newRecords = try await FDEcardRequests.getTradeRecord(page: page)
            if !newRecords.isEmpty {
                records.append(contentsOf: newRecords)
                page += 1
            } else {
                endReached = true
            }
        } catch {
            recordError = error.localizedDescription
        }
    }
    
    var body: some View {
        LoadingPage(action: initialFetch) {
            List {
                Section {
                    LabeledContent("ECard Balance", value: "132")
                }
                
                Section {
                    ForEach(records) { record in
                        FDTradeRecordView(record: record)
                            .task {
                                if record == records.last && !endReached {
                                    await loadMoreRecords()
                                }
                            }
                    }
                } header: {
                    Text("Transaction Record")
                } footer: {
                    if !endReached {
                        LoadingFooter(loading: $recordLoading,
                                      errorDescription: recordError,
                                      action: loadMoreRecords)
                    }
                }
            }
            .navigationTitle("ECard Information")
        }
    }
}

struct FDTradeRecordView: View {
    let record: FDTradeRecord
    
    var body: some View {
        LabeledContent {
            Text(record.amount)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        } label: {
            VStack(alignment: .leading) {
                Text(record.location)
                Text(record.createTime)
                    .foregroundColor(.secondary)
                    .font(.callout)
            }
        }
    }
}

struct FDECardPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FDEcardPage()
        }
    }
}
