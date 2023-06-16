import SwiftUI

struct FDLibraryPage: View {
    var body: some View {
        AsyncContentView { () -> [Int] in
            try await FDWebVPNAPI.login()
            return try await FDLibraryAPI.getLibrarySeats()
        } content: { libraries in
            List {
                LabeledContent("文科图书馆", value: String(libraries[0]))
                LabeledContent("理科图书馆", value: String(libraries[1]))
                LabeledContent("张江图书馆", value: String(libraries[2]))
                LabeledContent("枫林图书馆", value: String(libraries[3]))
                LabeledContent("江湾图书馆", value: String(libraries[4]))
            }
            .navigationTitle("Library Popularity")
        }
    }
}
