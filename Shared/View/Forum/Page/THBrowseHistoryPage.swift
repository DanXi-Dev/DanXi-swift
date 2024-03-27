import SwiftUI
import WrappingHStack

struct THBrowseHistoryPage: View {
    @ObservedObject private var model = THModel.shared
    @State private var showConfirmation = false
    private let calendar = Calendar.current
    
    private var todayHistory: [THBrowseHistory] {
        model.browseHistory.filter { history in
            calendar.isDateInToday(history.browseTime)
        }
    }
    
    private var yesterdayHistory: [THBrowseHistory] {
        model.browseHistory.filter { history in
            calendar.isDateInYesterday(history.browseTime)
        }
    }
    
    private var furtherHistory: [THBrowseHistory] {
        model.browseHistory.filter { history in
            !calendar.isDateInToday(history.browseTime) && !calendar.isDateInYesterday(history.browseTime)
        }
    }
    
    
    var body: some View {
        List {
            if !todayHistory.isEmpty {
                Section("Today") {
                    ForEach(todayHistory) { history in
                        BrowseHistoryView(history: history)
                    }
                }
            }
            
            if !yesterdayHistory.isEmpty {
                Section("Yesterday") {
                    ForEach(yesterdayHistory) { history in
                        BrowseHistoryView(history: history)
                    }
                }
            }
            
            if !furtherHistory.isEmpty {
                Section("Earlier") {
                    ForEach(furtherHistory) { history in
                        BrowseHistoryView(history: history)
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Recent Browsed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button {
                     showConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete Browse History", isPresented: $showConfirmation) {
            Button("Clear Browse History", role: .destructive) {
                withAnimation {
                    model.clearHistory()
                }
            }
        }
    }
}

fileprivate struct BrowseHistoryView: View {
    let history: THBrowseHistory
    
    var body: some View {
        NavigationListRow(value: THHoleLoader(holeId: history.id)) {
            VStack(alignment: .leading) {
                WrappingHStack(alignment: .leading) {
                    ForEach(history.tags) { tag in
                        THTagView(tag)
                    }
                }
                
                Text(history.content.inlineAttributed())
                    .font(.callout)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                
                HStack {
                    Text("#\(String(history.id))")
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
            Text(history.browseTime.formatted(.relative(presentation: .named, unitsStyle: .wide)))
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

