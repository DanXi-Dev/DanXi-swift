import SwiftUI

struct SearchTagPage: View {
    let tagname: String
    let divisionId: Int?
    @State private var endReached = false
    @State var holes: [THHole] = []
    
    func loadMoreHoles() async {
        do {
            let newHoles = try await networks.searchTag(tagName: tagname, divisionId: divisionId, startTime: holes.last?.iso8601UpdateTime)
            endReached = newHoles.isEmpty
            holes.append(contentsOf: newHoles)
        } catch {
            print("DANXI-DEBUG: load holes failed")
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(holes) { hole in
                    HoleView(hole: hole)
                        .background(NavigationLink("", destination: HoleDetailPage(hole: hole)).opacity(0))
                        .task {
                            if hole == holes.last {
                                await loadMoreHoles()
                            }
                        }
                }
            } footer: {
                if !endReached {
                    HStack() {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        if holes.isEmpty {
                            await loadMoreHoles()
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tagname)
    }
}

struct SearchTagPage_Previews: PreviewProvider {
    static var previews: some View {
        SearchTagPage(tagname: "test", divisionId: 1)
    }
}
