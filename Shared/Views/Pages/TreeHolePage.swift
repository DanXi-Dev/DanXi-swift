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
                    NavigationLink(destination: THThread(hole: hole)) {
                        THHoleView(hole: hole)
                    }
                    
                }
            } header: {
                VStack(alignment: .leading, spacing: 1.5) {
                    divisionSelector
                    Label("pinned", systemImage: "pin.fill")
                }
            }
            
            Section {
                ForEach(data.holes) { hole in
                    NavigationLink(destination: THThread(hole: hole)) {
                        THHoleView(hole: hole)
                    }
                }
            } header: {
                Label("main_section", systemImage: "text.bubble.fill")
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
                        } else {
                            await data.fetchMoreHoles()
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("bottom_reached")
                        Spacer()
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
                        Image(systemName: "plus.circle")
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
        .task { // data initialization
            if data.notInitiazed {
                Task {
                    await data.refresh(initial:true)
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
