import SwiftUI

struct TreeHolePage: View {
    @EnvironmentObject var accountState: THAccountModel
    @StateObject var data = THData()
    @State var showNewPostPage = false
    
    var body: some View {
#if os(watchOS)
        List {
            listContent
        }
        .navigationTitle(data.currentDivision.name)
#else
        List() {
            Section {
                ForEach(data.currentDivision.pinned) { hole in
                    THHoleView(hole: hole)
                        .background(NavigationLink("", destination: THThread(hole: hole)).opacity(0))
                    
                }
            } header: {
                VStack(alignment: .leading, spacing: 1.5) {
                    divisionSelector
                    if !data.currentDivision.pinned.isEmpty {
                        Label("pinned", systemImage: "pin.fill")
                    }
                }
            }
            
            Section {
                ForEach(data.holes) { hole in
                    THHoleView(hole: hole)
                        .background(NavigationLink("", destination: THThread(hole: hole)).opacity(0))
                        .task {
                            if hole == data.holes.last {
                                await data.fetchMoreHoles()
                            }
                        }
                }
            } header: {
                if !data.currentDivision.pinned.isEmpty {
                    Label("main_section", systemImage: "text.bubble.fill")
                }
            } footer: {
                if !data.endReached {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        if data.notInitiazed {
                            await data.refresh(initial: true)
                        }
                    }
                }
            }
        }
        .refreshable {
            await data.refresh()
        }
        .listStyle(.grouped)
        .navigationTitle(data.currentDivision.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}, label: {
                    Image(systemName: "bell")
                })
                .font(.subheadline)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Group {
                    Button(action: { showNewPostPage = true }, label: {
                        Image(systemName: "square.and.pencil")
                    })
                    .sheet(isPresented: $showNewPostPage) {
                        THNewPost()
                    }
                    
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
        Picker("divisions", selection: $data.currentDivision) {
            ForEach(data.divisions, id: \.self) {division in
                Text(division.name)
            }
        }
#if !os(watchOS)
        .pickerStyle(.segmented)
#endif
        .padding()
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
