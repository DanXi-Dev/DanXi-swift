import SwiftUI
import ViewUtils

struct BrowseHistoryPage: View {
    @Environment(\.calendar) private var calendar
    
    @ObservedObject private var historyStore = HistoryStore.shared
    @State private var showConfirmation = false
    
    private var todayHistory: [ForumBrowseHistory] {
        historyStore.browseHistory.filter { history in
            calendar.isDateInToday(history.lastBrowsed)
        }
    }
    
    private var yesterdayHistory: [ForumBrowseHistory] {
        historyStore.browseHistory.filter { history in
            calendar.isDateInYesterday(history.lastBrowsed)
        }
    }
    
    private var furtherHistory: [ForumBrowseHistory] {
        historyStore.browseHistory.filter { history in
            !calendar.isDateInToday(history.lastBrowsed) && !calendar.isDateInYesterday(history.lastBrowsed)
        }
    }
    
    var body: some View {
        List {
            if !todayHistory.isEmpty {
                ForEach(Array(todayHistory.enumerated()), id: \.offset) { index, history in
                    if index == 0 {
                        Section {
                            BrowseHistoryView(history: history)
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        } header: {
                            Text("Today", bundle: .module)
                        }
                    } else {
                        Section {
                            BrowseHistoryView(history: history)
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        }
                    }
                }
            }
            
            if !yesterdayHistory.isEmpty {
                ForEach(Array(yesterdayHistory.enumerated()), id: \.offset) { index, history in
                    if index == 0 {
                        Section {
                            BrowseHistoryView(history: history)
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        } header: {
                            Text("Yesterday", bundle: .module)
                        }
                    } else {
                        Section {
                            BrowseHistoryView(history: history)
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        }
                    }
                }
            }
            
            if !furtherHistory.isEmpty {
                ForEach(Array(furtherHistory.enumerated()), id: \.offset) { index, history in
                    if index == 0 {
                        Section {
                            BrowseHistoryView(history: history)
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        } header: {
                            Text("Earlier", bundle: .module)
                        }
                    } else {
                        Section {
                            BrowseHistoryView(history: history)
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        }
                    }
                }
            }
        }
        .compactSectionSpacing(spacing: 8)
        .navigationTitle(String(localized: "Recent Browsed", bundle: .module))
        .tint(.primary)
        .navigationBarTitleDisplayMode(.inline)
        .watermark()
        .toolbar {
            ToolbarItem {
                Button {
                    showConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog(String(localized: "Delete Browse History", bundle: .module), isPresented: $showConfirmation) {
            Button(role: .destructive) {
                withAnimation {
                    historyStore.clearHistory()
                }
            } label: {
                Text("Clear Browse History", bundle: .module)
            }
        }
    }
}

private struct BrowseHistoryView: View {
    let history: ForumBrowseHistory
    
    var body: some View {
        DetailLink(value: HoleLoader(holeId: history.id)) {
            VStack(alignment: .leading) {
                WrappingHStack(alignment: .leading) {
                    ForEach(Array(history.tags.enumerated()), id: \.offset) { _, tag in
                        TagView(tag)
                    }
                }
                
                Text(history.content.inlineAttributed())
                    .font(.callout)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                
                HStack {
                    Text(verbatim: "#\(String(history.id))")
                    Spacer()
                    time
                    Spacer()
                    info
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 1)
            }
        }
    }
    
    private var time: some View {
        HStack(alignment: .center, spacing: 3) {
            Image(systemName: "clock.arrow.circlepath")
            Text(history.lastBrowsed.formatted(.relative(presentation: .named, unitsStyle: .wide)))
        }
    }
    
    private var info: some View {
        HStack(alignment: .center, spacing: 15) {
            HStack(alignment: .center, spacing: 3) {
                Image(systemName: "eye")
                Text(String(history.view))
            }
            
            HStack(alignment: .center, spacing: 3) {
                Image(systemName: "ellipsis.bubble")
                Text(String(history.reply))
            }
        }
        .font(.caption2)
    }
}
