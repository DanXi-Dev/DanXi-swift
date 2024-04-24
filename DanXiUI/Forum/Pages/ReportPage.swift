import SwiftUI
import ViewUtils
import DanXiKit

struct ReportPage: View {
    @StateObject private var model = ReportModel()
    
    var body: some View {
        ForumList {
            AsyncCollection(model.reports, endReached: model.endReached, action: model.loadMoreReports) { report in
                ReportView(report: report)
            }
        }
        .environmentObject(model)
        .listStyle(.inset)
        .navigationTitle("Reports Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                filter
            }
        }
        .animation(.default, value: model.reports)
        .watermark()
    }
    
    private var filter: some View {
        Menu {
            Picker("Filter Report", selection: $model.filterOption) {
                Text("Not Dealt").tag(ReportModel.FilterOption.notDealt)
                Text("Dealt").tag(ReportModel.FilterOption.dealt)
                Text("All Reports").tag(ReportModel.FilterOption.all)
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

private struct ReportView: View {
    @EnvironmentObject private var model: ReportModel
    
    let report: Report
    
    var body: some View {
        DetailLink(value: HoleLoader(report.floor)) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Incident ID: \(String(report.id))")
                    Spacer()
                    Text(report.timeCreated.formatted())
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text("Report reason: ") + Text(report.reason)
                    .bold()
                    .foregroundColor(.red)
                
                
                GroupBox {
                    SimpleFloorView(floor: report.floor)
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
