import SwiftUI

struct THReportPage: View {
    @StateObject var model = THReportModel()
    
    var body: some View {
        List {
            Section {
                AsyncCollection(model.reports, endReached: model.endReached,
                                action: model.loadMoreReports) { report in
                    ReportView(report: report)
                }
            }
            .environmentObject(model)
        }
        .listStyle(.inset)
        .navigationTitle("Reports Management")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                filter
            }
        }
        .animation(.default, value: model.reports)
    }
    
    private var filter: some View {
        Menu {
            Picker("Filter Report", selection: $model.filterOption) {
                Text("Not Dealt").tag(THReportModel.FilterOption.notDealt)
                Text("Dealt").tag(THReportModel.FilterOption.dealt)
                Text("All Reports").tag(THReportModel.FilterOption.all)
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

fileprivate struct ReportView: View {
    @EnvironmentObject var model: THReportModel
    
    let report: THReport
    
    var body: some View {
        NavigationListRow(value: THHoleLoader(report.floor)) {
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
                
                
                GroupBox {
                    THSimpleFloor(floor: report.floor)
                }
                
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
        }
        .swipeActions {
            if !report.dealt {
                Button(role: .destructive) {
                    Task {
                        await model.markAsDealt(report)
                    }
                } label: {
                    Image(systemName: "checkmark")
                }
                .tint(.accentColor)
            }
        }
    }
}
