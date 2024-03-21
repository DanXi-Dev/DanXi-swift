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
                    List {
                        ForEach(ranks) { rank in
                            RankView(rank: rank)
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

fileprivate struct GPABin: Identifiable {
    public var id = UUID()
    public var gpa: Double
    public var gpaStart: Double
    public var gpaEnd: Double
    public var count: Int
    
    init(gpaStart: Double, gpaEnd: Double, count: Int) {
        self.gpa = (gpaStart + gpaEnd) / 2
        self.gpaStart = gpaStart
        self.gpaEnd = gpaEnd
        self.count = count
    }
}

@available(iOS 17, *)
fileprivate struct RankChart: View {
    private let bins: [GPABin]
    private let myRank: FDRank?
    let color: Color = .accentColor
    
    init(_ ranks: [FDRank], myRank: FDRank?) {
        self.bins = RankChart.prepareDataForDensityChart(ranks: ranks, binWidth: 0.1)
        self.myRank = myRank
    }
    
    private var areaBackground: Gradient {
        return Gradient(colors: [color.opacity(0.5), .clear])
    }
    
    static func prepareDataForDensityChart(ranks: [FDRank], binWidth: Double) -> [GPABin] {
        // Determine the min and max GPA to set the range of bins
        guard let minGPA = ranks.min(by: { $0.gpa < $1.gpa })?.gpa,
              let maxGPA = ranks.max(by: { $0.gpa < $1.gpa })?.gpa else {
            return []
        }

        // Calculate the number of bins needed based on the binWidth
        let binsCount = Int(((maxGPA - minGPA) / binWidth).rounded(.up))
        
        // Initialize the bins
        var bins = Array(repeating: 0, count: binsCount)
        
        // Assign ranks to bins
        for rank in ranks {
            let binIndex = Int((rank.gpa - minGPA) / binWidth)
            bins[min(binIndex, binsCount - 1)] += 1
        }
        
        // Convert bins
        let binnedData = bins.enumerated().map { index, count in
            let rangeStart = minGPA + binWidth * Double(index)
            let rangeEnd = rangeStart + binWidth
            return GPABin(gpaStart: rangeStart, gpaEnd: rangeEnd, count: count)
        }
        
        return binnedData.filter({ i in i.count > 0})
    }
    
    private func getBarMarkForegroundStyle(bin: GPABin) -> Color {
        guard let myRank else {
            return color
        }
        
        if bin.gpaStart <= myRank.gpa && myRank.gpa <= bin.gpaEnd {
            return color
        }
        return .secondary
    }
    
    var body: some View {
        Chart(bins) { bin in
            BarMark(
                x: .value("GPA", bin.gpa),
                y: .value("Density", bin.count)
            )
//            .foregroundStyle(getBarMarkForegroundStyle(bin: bin))
            .foregroundStyle(color)
        }
        .chartXVisibleDomain(length: 3)
        .chartScrollPosition(initialX: 1)
        .chartScrollableAxes(.horizontal)
        .chartXAxisLabel("GPA")
        .frame(height: 300)
        .padding(.top, 10)
    }
}
