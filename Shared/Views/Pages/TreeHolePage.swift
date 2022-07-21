import SwiftUI

struct TreeHolePage: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var accountState: THAccountModel
    @StateObject var data = THData()
    
    var body: some View {
#if os(watchOS)
        List {
            listContent
        }
        .navigationTitle(data.currentDivision.name)
#else
        ScrollView{
            LazyVStack {
                listContent
                
                if !data.endReached {
                    ProgressView()
                        .task {
                            if data.notInitiazed {
                                await data.initialFetch()
                            } else {
                                await data.fetchMoreHoles()
                            }
                        }
                }
            }
        }
        .navigationTitle(data.currentDivision.name)
        .background(Color(uiColor: colorScheme == .dark ? .systemBackground : .secondarySystemBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}, label: {
                    Image(systemName: "bell")
                })
                .font(.subheadline)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Group {
                    Button(action: {}, label: {
                        Image(systemName: "plus.circle")
                    })
                    Menu(content: {
                        Button(action: {}, label: {
                            Text("option1")
                        })
                        Button(action: {}, label: {
                            Text("option2")
                        })
                    }, label: {
                        Image(systemName: "ellipsis.circle")
                    })
                }
                .font(.subheadline)
            }
        }
        
#endif
    }
    
    @ViewBuilder
    private var listContent: some View {
        if !data.divisions.isEmpty {
            divisionSelector
        }
        
        ForEach(data.currentDivision.pinned) { hole in
            NavigationLink(destination: THThread(hole: hole)) {
                THHoleView(hole: hole)
            }
        }
        
        ForEach(data.holes) { hole in
            NavigationLink(destination: THThread(hole: hole)) {
                THHoleView(hole: hole)
            }
        }
    }
    
    private var divisionSelector: some View {
        Picker("Divisions", selection: $data.currentDivision) {
            ForEach(data.divisions, id: \.self) {division in
                Text(division.name)
            }
        }
#if !os(watchOS)
        .pickerStyle(.segmented)
#endif
        .padding()
        .task { // data initialization
            if data.notInitiazed {
                Task {
                    await data.initialFetch()
                }
            }
        }
        .onChange(of: data.currentDivision) { newValue in
            Task {
                await data.changeDivision(division: newValue) // change division
            }
        }
    }
    
}

struct TreeHolePage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TreeHolePage()
            TreeHolePage()
                .preferredColorScheme(.dark)
        }
    }
}
