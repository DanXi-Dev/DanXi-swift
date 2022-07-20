import SwiftUI

struct TreeHolePage: View {
    @EnvironmentObject var accountState: THSystem
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
            }
        }
        .navigationTitle(data.currentDivision.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                toolbarLeft
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarRight
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
                THEntry(hole: hole)
            }
        }
        
        ForEach(data.holes) { hole in
            NavigationLink(destination: THThread(hole: hole)) {
                THEntry(hole: hole)
            }
        }
        
        if !data.endReached {
            ProgressView()
                .task {
                    if !data.notInitiazed {
                        await data.fetchMoreHoles()
                    }
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
        .task { // 数据初始化
            if data.notInitiazed {
                Task {
                    await data.initialFetch()
                }
            }
        }
        .onChange(of: data.currentDivision) { newValue in
            Task {
                await data.changeDivision(division: newValue) // 切换分区
            }
        }
    }
    
    private var toolbarLeft: some View {
        Button(action: {}, label: {
            Image(systemName: "bell")
        })
        .font(.subheadline)
    }
    
    private var toolbarRight: some View {
        Group {
            Button(action: {}, label: {
                Image(systemName: "arrow.up.arrow.down")
            })
            Button(action: {}, label: {
                Image(systemName: "star")
            })
            Button(action: {}, label: {
                Image(systemName: "plus.circle")
            })
        }
        .font(.subheadline)
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
