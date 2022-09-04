import SwiftUI

struct ReportPage: View {
    
    @State var reportList: [THReport] = []
    @State var loading = true
    @State var initFinished = false
    @State var initError = ErrorInfo()
    
    init() { }
    
    init(reportList: [THReport]) {
        self._reportList = State(initialValue: reportList)
        self._loading = State(initialValue: false)
        self._initFinished = State(initialValue: true)
    }
    
    func loadReports() async {
        do {
            reportList = try await NetworkRequests.shared.loadReportsList()
            initFinished = true
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            initError = error.localizedErrorDescription
        } catch {
            initError = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        LoadingView(loading: $loading,
                    finished: $initFinished,
                    errorDescription: initError.description,
                    action: loadReports) {
            List {
                ForEach(reportList) { report in
                    ReportCell(report: report)
                    .swipeActions {
                        Button {
                            // TODO: mark
                        } label: {
                            Label("Mark as Dealt", systemImage: "checkmark")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Reports Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
}

struct ReportCell: View {
    let report: THReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Incident ID: \(String(report.id))")
                Spacer()
                Text(report.createTime.formatted())
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("Report reason: ") + Text(report.reason)
                .bold()
                .foregroundColor(.red)
            
            
            Group {
                if !report.floor.deleted {
                    FloorView(floor: report.floor, interactable: false)
                } else {
                    HStack {
                        Text(report.floor.content)
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        Spacer()
                    }
                }
            }
            .padding(10)
            .background(Color.secondary.opacity(0.05))
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(10)
            .padding(.bottom)
            .background(NavigationLink(destination: HoleDetailPage(targetFloorId: report.floor.id)) {
                EmptyView()
            }.opacity(0))
        }
    }
}

struct ReportPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportPage(reportList: PreviewDecode.decodeList(name: "report-list"))
        }
    }
}
