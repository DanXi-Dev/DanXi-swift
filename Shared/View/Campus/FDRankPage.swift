import SwiftUI

struct FDRankPage: View {    
    var body: some View {
        AsyncContentView { () -> [FDRank] in
            try await FDAcademicAPI.login()
            return try await FDAcademicAPI.getGPA()
        } content: { ranks in
            if let myRank = ranks.filter({ $0.isMe }).first {
                Section {
                    HStack {
                        Text("Total credit \(String(format: "%.1f", myRank.credit)), rank \(String(myRank.rank))")
                            .foregroundColor(.secondary)
                            .font(.callout)
                        Spacer()
                        Text(String(myRank.gpa))
                            .fontWeight(.bold)
                    }
                }
                
                Section {
                    ForEach(ranks) { rank in
                        RankView(rank: rank)
                    }
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
