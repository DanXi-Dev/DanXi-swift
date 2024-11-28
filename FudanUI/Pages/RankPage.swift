import Charts
import FudanKit
import SwiftUI
import ViewUtils

struct RankPage: View {
    @State private var showSheet = false
    let previewRanks: [Rank]?
    
    init(previewRanks: [Rank]) {
        self.previewRanks = previewRanks
    }
    
    init() {
        previewRanks = nil
    }
    
    var body: some View {
        AsyncContentView {
            if let previewRanks {
                return previewRanks
            }
            
            return try await UndergraduateCourseAPI.getRanks()
        } content: { ranks in
            List {
                let myRank = ranks.first(where: { $0.isMe })
                Section {
                    if let myRank = myRank {
                        LabeledContent {
                            Text(String(myRank.gradePoint))
                        } label: {
                            Text("My GPA", bundle: .module)
                        }
                        LabeledContent {
                            Text(String(myRank.rank))
                        } label: {
                            Text("My Rank", bundle: .module)
                        }
                        LabeledContent {
                            Text(String(format: "%.1f", myRank.credit))
                        } label: {
                            Text("My Credit", bundle: .module)
                        }
                    }
                    
                    Button {
                        showSheet = true
                    } label: {
                        Text("Show all GPA rank", bundle: .module)
                    }
                }
                
                if #available(iOS 17, *) {
                    Section {
                        RankChart(ranks, myRank: myRank)
                    } header: {
                        Text("GPA Distribution", bundle: .module)
                    }
                }
            }
            .sheet(isPresented: $showSheet) {
                NavigationStack {
                    Form {
                        List {
                            ForEach(ranks) { rank in
                                RankView(rank: rank)
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showSheet = false
                            } label: {
                                Text("Done", bundle: .module)
                            }
                        }
                    }
                    .navigationTitle(String(localized: "GPA Rank", bundle: .module))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .navigationTitle(String(localized: "GPA Rank", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct RankView: View {
    let rank: Rank
    
    var body: some View {
        HStack {
            Text(verbatim: "#\(String(rank.rank))")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            if rank.isMe {
                Image(systemName: "person.fill")
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(rank.gradePoint))
                    .font(.headline)
                Text(rank.major)
                    .font(.callout)
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", rank.credit)) Credit", bundle: .module)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(rank.isMe ? .accentColor : .primary)
    }
}

@available(iOS 17, *)
private struct RankChart: View {
    private let ranks: [Rank]
    private let myRank: Rank?
    let color: Color = .accentColor
    
    @State private var chartSelection: Int?
    
    init(_ ranks: [Rank], myRank: Rank?) {
        self.ranks = ranks.sorted(by: { a, b in
            a.gradePoint < b.gradePoint
        })
        self.myRank = myRank
    }
    
    private var areaBackground: Gradient {
        return Gradient(colors: [color.opacity(0.5), .clear])
    }
    
    var body: some View {
        Chart(Array(ranks.enumerated()), id: \.offset) { index, rank in
            LineMark(
                x: .value(String(localized: "Rank", bundle: .module), ranks.count - index - 1), // The -1 eliminates the gap at the start of the chart
                y: .value(String(localized: "GPA", bundle: .module), rank.gradePoint)
            )
            .foregroundStyle(color)
            
            if let myRank = self.myRank {
                PointMark(
                    x: .value(String(localized: "Rank", bundle: .module), myRank.rank),
                    y: .value(String(localized: "GPA", bundle: .module), myRank.gradePoint)
                )
                .symbolSize(72)
                #if !os(watchOS)
                .foregroundStyle(Color(uiColor: .secondarySystemGroupedBackground))
                #endif
                PointMark(
                    x: .value(String(localized: "Rank", bundle: .module), myRank.rank),
                    y: .value(String(localized: "GPA", bundle: .module), myRank.gradePoint)
                )
            }
            
            AreaMark(
                x: .value(String(localized: "Rank", bundle: .module), ranks.count - index - 1), // The -1 eliminates the gap at the start of the chart
                y: .value(String(localized: "GPA", bundle: .module), rank.gradePoint)
            )
            .foregroundStyle(areaBackground)
            
            if let selected = chartSelection, selected > 0 && selected <= ranks.count {
                let x = max(1, selected)
                let value = ranks[ranks.count - x]
                RuleMark(x: .value(String(localized: "Rank", bundle: .module), x))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.secondary)
                PointMark(
                    x: .value(String(localized: "Rank", bundle: .module), x),
                    y: .value(String(localized: "GPA", bundle: .module), value.gradePoint)
                )
                .symbolSize(70)
                #if !os(watchOS)
                .foregroundStyle(Color(uiColor: .secondarySystemGroupedBackground))
                #endif
                PointMark(
                    x: .value(String(localized: "Rank", bundle: .module), x),
                    y: .value(String(localized: "GPA", bundle: .module), value.gradePoint)
                )
                .symbolSize(40)
            }
        }
        .overlay(alignment: .bottomLeading, content: {
            if !ranks.isEmpty, let selected = chartSelection {
                let x = max(1, selected)
                let value = ranks[ranks.count - x]
                Grid(alignment: .leading) {
                    GridRow {
                        Text("GPA: ", bundle: .module)
                        Text(String(format: "%.2f", value.gradePoint))
                    }
                    GridRow {
                        Text("Rank: ", bundle: .module)
                        Text(verbatim: "\(value.rank)")
                    }
                }
                .padding(8)
                .background(.regularMaterial)
                .cornerRadius(8)
                .font(.system(.caption, design: .rounded))
                .padding(.bottom, 56)
                .padding(.leading, 24)
            }
        })
        .chartXScale(domain: 0 ... ranks.count)
        .chartXAxisLabel(String(localized: "Rank", bundle: .module))
        .chartYAxisLabel(String(localized: "GPA", bundle: .module))
        .chartXSelection(value: $chartSelection)
        .frame(height: 300)
        .padding(.top, 8)
    }
}

#Preview {
    RankPage(previewRanks: decodePreviewData(filename: "ranks"))
        .previewPrepared()
}
