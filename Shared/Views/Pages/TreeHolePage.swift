import SwiftUI

struct TreeHolePage: View {
    @StateObject var vm: TreeHolePageViewModel = TreeHolePageViewModel()
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        if !appModel.hasAccount {
            TreeHoleLoginPrompt() }
        else {
            NavigationView {
                ScrollView {
                    VStack(alignment: .center) {
                        switcher
                        
                        ForEach(vm.holes) { hole in
                            NavigationLink(destination: TreeHolePost(holeId: hole.hole_id, floors: hole.floors.prefetch)) {
                                TreeHoleEntry(hole: hole)
                            }
                        }
                        
                        if vm.endReached == false {
                            ProgressView()
                                .task {
                                    // Prevent duplicate refresh
                                    if vm.currentDivision != OTDivision.dummy && vm.initialized && !vm.isLoading {
                                        await vm.loadNextPage(token: appModel.userCredential!)
                                    }
                                }
                        } else {
                            Text("endreached")
                        }
                    }
                }
                .navigationTitle(vm.currentDivision.name)
                //.navigationBarTitleDisplayMode(.inline)
#if !os(watchOS)
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
        }
    }
    
    private var switcher: some View {
        Picker("division", selection: $vm.currentDivision) {
            ForEach(vm.divisions, id: \.self) {division in
                Text(division.name)
            }
        }
#if !os(watchOS)
        .pickerStyle(.segmented)
#endif
        .padding()
        .task {
            if !vm.initialized && !vm.isLoading {
                Task {
                    await vm.fetchDivisions(token: appModel.userCredential!)
                    vm.initialized = true
                }
            }
        }
        .onChange(of: vm.currentDivision) { newValue in
            vm.changeDivision(token: appModel.userCredential!, newDivision: newValue)
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
    static let appModel = AppModel()
    
    static var previews: some View {
        Group {
            TreeHolePage()
                .environmentObject(appModel)
        }
    }
}
