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
        .navigationTitle(String(localized: "Reports Management", bundle: .module))
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
            Picker(selection: $model.filterOption) {
                Text("Not Dealt", bundle: .module).tag(ReportModel.FilterOption.notDealt)
                Text("Dealt", bundle: .module).tag(ReportModel.FilterOption.dealt)
                Text("All Reports", bundle: .module).tag(ReportModel.FilterOption.all)
            } label: {
                Text("Filter Report", bundle: .module)
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
                    Text("Incident ID: \(String(report.id))", bundle: .module)
                    Spacer()
                    Text(report.timeCreated.formatted())
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text("Report reason: ", bundle: .module) + Text(report.reason)
                    .bold()
                    .foregroundColor(.red)
                
                
                GroupBox {
                    SimpleFloorView(floor: report.floor)
                }
                
                if report.dealt {
                    Group {
                        if let dealtBy = report.dealtBy {
                            Text("Dealt by \(String(dealtBy))", bundle: .module)
                        } else {
                            Text("Dealt", bundle: .module)
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
