import SwiftUI
import FudanKit
import Charts
import ViewUtils

struct RankPage: View {
    @State private var showSheet = false
    
    var body: some View {
        AsyncContentView { _ in
            return try await UndergraduateCourseAPI.getRanks()
        } content: { ranks in
            List {
                let myRank = ranks.first(where: { $0.isMe })
                Section {
                    if let myRank = myRank {
                        LabeledContent {
                            Text(String(myRank.gradePoint))
                        } label: {
                            Text("My GPA")
                        }
                        LabeledContent {
                            Text(String(myRank.rank))
                        } label: {
                            Text("My Rank")
                        }
                        LabeledContent {
                            Text(String(format: "%.1f", myRank.credit))
                        } label: {
                            Text("My Credit")
                        }
                    }
                    
                    Button {
                        showSheet = true
                    } label: {
                        Text("Show all GPA rank")
                    }
                }
                
                if #available(iOS 17, *) {
                    Section("GPA Distribution") {
                        RankChart(ranks, myRank: myRank)
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
                                Text("Done")
                            }
                        }
                    }
                    .navigationTitle("GPA Rank")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .navigationTitle("GPA Rank")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct RankView: View {
    let rank: Rank
    
    var body: some View {
        HStack {
            Text("#\(String(rank.rank))")
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
                Text("\(String(format: "%.1f", rank.credit)) Credit")
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
        Chart(Array(ranks.enumerated()), id: \.offset) { (index, rank) in
            LineMark(
                x: .value("Rank", ranks.count - index - 1), // The -1 eliminates the gap at the start of the chart
                y: .value("GPA", rank.gradePoint)
            )
            .foregroundStyle(color)
            
            AreaMark(
                x: .value("Rank", ranks.count - index - 1), // The -1 eliminates the gap at the start of the chart
                y: .value("GPA", rank.gradePoint)
            )
            .foregroundStyle(areaBackground)
            
            if let selected = chartSelection, selected > 0 && selected <= ranks.count {
                let x = max(1, selected)
                let value = ranks[ranks.count - x]
                RuleMark(x: .value("Rank", x))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.secondary)
                PointMark(
                    x: .value("Rank", x),
                    y: .value("GPA", value.gradePoint)
                )
                .symbolSize(70)
                .foregroundStyle(Color(uiColor: .secondarySystemGroupedBackground))
                PointMark(
                    x: .value("Rank", x),
                    y: .value("GPA", value.gradePoint)
                )
                .symbolSize(40)
            }
        }
        .overlay(alignment: .bottomLeading, content: {
            if let selected = chartSelection {
                let x = max(1, selected)
                let value = ranks[ranks.count - x]
                Grid(alignment: .leading) {
                    GridRow {
                        Text("GPA: ")
                        Text(String(format: "%.2f", value.gradePoint))
                    }
                    GridRow {
                        Text("Rank: ")
                        Text("\(value.rank)")
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
        .chartXAxisLabel(String(localized:"Rank"))
        .chartYAxisLabel(String(localized:"GPA"))
        .chartXSelection(value: $chartSelection)
        .frame(height: 300)
        .padding(.top, 8)
    }
}
