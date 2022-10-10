import SwiftUI

struct ReportPage: View {
    enum FilterOption: Int {
        case notDealt = 0
        case dealt = 1
        case all = 2
    }
    
    @State var reportList: [THReport] = []
    @State var loading = false
    @State var errorInfo = ""
    @State var endReached = false
    @State var filterOption = FilterOption.notDealt
    
    init() { }
    
    init(reportList: [THReport]) {
        self._reportList = State(initialValue: reportList)
    }
    
    func loadMoreReports() async {
        do {
            let newReports = try await DXNetworks.shared.loadReports(offset: reportList.count, range: filterOption.rawValue)
            endReached = newReports.isEmpty
            let ids = reportList.map(\.id)
            let filteredReports = newReports.filter { !ids.contains($0.id) }
            reportList.append(contentsOf: filteredReports)
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker(selection: $filterOption) {
                    Text("Not Dealt").tag(FilterOption.notDealt)
                    Text("Dealt").tag(FilterOption.dealt)
                    Text("All Reports").tag(FilterOption.all)
                } label: {
                    Label("Filter Reports", systemImage: "line.3.horizontal.decrease.circle")
                }
                .onChange(of: filterOption) { newValue in
                    Task {
                        reportList = []
                        await loadMoreReports()
                    }
                }
            }
            
            Section {
                ForEach(reportList) { report in
                    ReportCell(report: report)
                        .task {
                            if report == reportList.last {
                                await loadMoreReports()
                            }
                        }
                }
            } footer: {
                if !endReached {
                    LoadingFooter(loading: $loading,
                                  errorDescription: errorInfo,
                                  action: loadMoreReports)
                }
            }
        }
        .task {
            await loadMoreReports()
        }
        .navigationTitle("Reports Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReportCell: View {
    @State var report: THReport
    
    @State var showBanSheet = false
    @State var showDeleteSheet = false
    
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
            .padding(.bottom, 5)
            
            if report.dealt {
                Group {
                    if let dealtBy = report.dealtBy {
                        Text("Dealt by \(String(dealtBy))")
                    } else {
                        Text("Dealt")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .backgroundLink {
            HoleDetailPage(targetFloorId: report.floor.id)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                // TODO: mark
            } label: {
                Label("Mark as Dealt", systemImage: "checkmark")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !report.floor.deleted {
                Button {
                    showDeleteSheet = true
                } label: {
                    Label("Remove Floor", systemImage: "trash")
                }
                .tint(.red)
            }
            
            Button {
                showBanSheet = true
            } label: {
                Label("Ban User", systemImage: "person.fill.xmark")
            }
        }
        .sheet(isPresented: $showBanSheet) {
            BanForm(divisionId: 0)
        }
        .sheet(isPresented: $showDeleteSheet) {
            DeleteForm(floor: $report.floor)
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
