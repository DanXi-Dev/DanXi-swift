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
                let myRank = ranks.filter({ $0.isMe }).first
                RankChart(ranks, myRank: myRank)
                if let myRank = myRank {
                    LabeledContent {
                        Text(String(myRank.rank))
                    } label: {
                        Label("My Rank", systemImage: "number")
                    }
                    LabeledContent {
                        Text(String(myRank.gpa))
                    } label: {
                        Label("My GPA", systemImage: "graduationcap.fill")
                    }
                    LabeledContent {
                        Text(String(format: "%.1f", myRank.credit))
                    } label: {
                        Label("My Credit", systemImage: "person.fill")
                    }
                }
                Button {
                    showSheet = true
                } label: {
                    Label("Show all GPA rank", systemImage: "info.circle")
                }
                .sheet(isPresented: $showSheet) {
                    List {
                        ForEach(ranks) { rank in
                            RankView(rank: rank)
                        }
                    }
                }
            }
            .navigationTitle("GPA Rank")
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

fileprivate struct RankChart: View {
    private let ranks: [FDRank]
    @State private var selectedRank: FDRank?
    
    init(_ ranks: [FDRank], myRank: FDRank?) {
        // invert the label in x axis
        self.ranks = ranks.map { rank in
            var reversedRank = rank
            reversedRank.rank = ranks.count - rank.rank
            return reversedRank
        }
        
        if let myRank = myRank {
            var myRankReversed = myRank
            myRankReversed.rank = ranks.count - myRank.rank
            self._selectedRank = State(initialValue: myRankReversed)
        } else {
            self._selectedRank = State(initialValue: nil)
        }
    }
    
    private func findElement(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> FDRank? {
        let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        if let rank = proxy.value(atX: relativeXPosition) as Int? {
            // Find the closest rank element
            var minDistance: Int = .max
            var index: Int? = nil
            for i in ranks.indices {
                let distance = rank - ranks[i].rank
                if abs(distance) < minDistance {
                    minDistance = abs(distance)
                    index = i
                }
            }
            
            if let index {
                return ranks[index]
            }
        }
        return nil
    }
    
    var body: some View {
        Chart(ranks) { rank in
            LineMark(x: .value("Rank", rank.rank),
                     y: .value("GPA", rank.gpa))
        }
        .chartXAxis(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let rank = findElement(location: value.location, proxy: proxy, geometry: geo)
                                if selectedRank?.rank == rank?.rank {
                                    selectedRank = nil
                                } else {
                                    selectedRank = rank
                                }
                            }
                            .exclusively(
                                before: DragGesture()
                                    .onChanged { value in
                                        selectedRank = findElement(location: value.location, proxy: proxy, geometry: geo)
                                    }
                            )
                    )
            }
        }
        .chartBackground { proxy in
            ZStack(alignment: .bottomLeading) {
                GeometryReader { geo in
                    if let selectedRank = selectedRank {
                        let startPositionX1 = proxy.position(forX: selectedRank.rank) ?? 0
                        let lineX = startPositionX1 + geo[proxy.plotAreaFrame].origin.x
                        let lineHeight = geo[proxy.plotAreaFrame].maxY
                        let boxWidth: CGFloat = 80
                        let boxOffset = max(0, min(geo.size.width - boxWidth, lineX - boxWidth / 2))
                        
                        Rectangle()
                            .fill(.red)
                            .frame(width: 2, height: lineHeight)
                            .position(x: lineX, y: lineHeight / 2)
                        
                        VStack(alignment: .leading) {
                            Group {
                                Text("GPA: \(String(format: "%.2f", selectedRank.gpa))")
                                Text("Credit: \(String(format: "%.1f", selectedRank.credit))")
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            Text("#\(ranks.count - selectedRank.rank)") // change the reversed rank back to original
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                        }
                        .frame(width: boxWidth, alignment: .leading)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondarySystemBackground)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary.opacity(0.7))
                            }
                            .padding(.horizontal, -8)
                            .padding(.vertical, -4)
                        }
                        .offset(x: boxOffset)
                    }
                }
            }
        }
        .frame(height: 300)
    }
}
