import SwiftUI

public struct CommunityPage: View {
    @State private var path = NavigationPath()
    
    public init() { }
    
    public var body: some View {
        NavigationStack(path: $path) {
            List {
                titleSection
                
                Section {
                    NavigationLink(value: CommunitySection.curriculum) {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .foregroundColor(.orange)
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text("Curriculum", bundle: .module)
                                    .font(.headline)
                                Text("Curriculum Introduction", bundle: .module)
                                    .font(.callout)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                
                Section {
                    NavigationLink(value: CommunitySection.innovation) {
                        HStack {
                            Image(systemName: "building.columns")
                                .foregroundColor(.purple)
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text("Innovation Bank", bundle: .module)
                                    .font(.headline)
                                Text("Innovation Bank Introduction", bundle: .module)
                                    .font(.callout)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: CommunitySection.self) { destination in
                    switch destination {
                    case .curriculum:
                        CurriculumEmbeddedContent(path: $path)
                    case .innovation:
                        InnovationHomePage()
                    }
            }
        }
    }
    
    private var titleSection: some View {
        Section {
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(.pink)
                        .font(.largeTitle)
                        .padding()
                        .background {
                            Circle()
                                .fill(Color.white)
                        }
                    Text("DanXi Community", bundle: .module)
                        .bold()
                        .font(.largeTitle)
                        .padding(.vertical, 5)
                    Text("DanXi Community Introduction", bundle: .module)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}

enum CommunitySection: Int, Identifiable, CaseIterable {
    case curriculum
    case innovation
    
    var id: Self {
        self
    }
}

#Preview {
    CommunityPage()
}
