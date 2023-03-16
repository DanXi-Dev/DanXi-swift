import SwiftUI

struct FDRankPage: View {
    @State var rankList: [FDRank] = []
    @State var myRank: FDRank?
    
    func initialLoad() async throws {
        try await FDAcademicAPI.login()
        rankList = try await FDAcademicAPI.getGPA()
        myRank = rankList.filter { $0.isMe }.first
    }
    
    var body: some View {
        LoadingPage(action: initialLoad) {
            List {
                
                if let myRank = myRank {
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
                }
                
                Section {
                    ForEach(rankList) { rank in
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
            }
            .navigationTitle("GPA Rank")
        }
    }
}

struct FDRankPage_Previews: PreviewProvider {
    static var previews: some View {
        FDRankPage()
    }
}
