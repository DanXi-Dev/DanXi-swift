import SwiftUI
import Charts

struct FDRankPage: View {
    @State private var showSheet = false
    
    var body: some View {
        AsyncContentView { () -> [FDRank] in
            try await FDAcademicAPI.login()
            return try await FDAcademicAPI.getGPA()
        } content: { ranks in
            List {
                let myRank = ranks.first(where: { $0.isMe })
                Section {
                    if let myRank = myRank {
                        LabeledContent {
                            Text(String(myRank.gpa))
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
            .navigationTitle("GPA Rank")
            .navigationBarTitleDisplayMode(.inline)
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
    }
}

fileprivate struct RankView: View {
    let rank: FDRank
    
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
                Text(String(rank.gpa))
                    .font(.headline)
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
    private let ranks: [FDRank]
    private let myRank: FDRank?
    let color: Color = .accentColor
    
    @State private var chartSelection: Int?
    
    init(_ ranks: [FDRank], myRank: FDRank?) {
        self.ranks = ranks.sorted(by: { a, b in
            a.gpa < b.gpa
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
                y: .value("GPA", rank.gpa)
            )
            .foregroundStyle(color)
            
            AreaMark(
                x: .value("Rank", ranks.count - index - 1), // The -1 eliminates the gap at the start of the chart
                y: .value("GPA", rank.gpa)
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
                    y: .value("GPA", value.gpa)
                )
                .symbolSize(100)
            }
        }
        .overlay(alignment: .bottomLeading, {
            if let selected = chartSelection {
                let x = max(1, selected)
                let value = ranks[ranks.count - x]
                Grid(alignment: .leading) {
                    GridRow {
                        Text("GPA: ")
                        Text(String(format: "%.2f", value.gpa))
                    }
                    GridRow {
                        Text("Rank: ")
                        Text("\(value.rank)")
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
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
