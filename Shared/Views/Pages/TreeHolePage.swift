//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @StateObject var vm: TreeHolePageViewModel = TreeHolePageViewModel()
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        List {
            Picker("division", selection: $vm.currentDivision) {
                ForEach(vm.divisions, id: \.self) {division in
                    Text("\(division.name) - \(division.description)")
                }
            }
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
            
            ForEach(vm.holes) { hole in
                NavigationLink(destination: TreeHoleDetailsPage(holeId: hole.hole_id, initialFloors: hole.floors.prefetch)) {
                    THPostView(hole: hole)
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
        .navigationTitle("treehole")
    }
    
    struct TreeHole_Previews: PreviewProvider {
        static var previews: some View {
            TreeHolePage()
        }
    }
}
