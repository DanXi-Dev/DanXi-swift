//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @StateObject var vm: TreeHolePageViewModel = TreeHolePageViewModel()
    
    var body: some View {
        List {
            Picker("division", selection: $vm.currentDivision) {
                ForEach(vm.divisions, id: \.self) {division in
                    Text("\(division.name) - \(division.description)")
                }
            }
            .task {
                if vm.divisions.isEmpty {
                    Task { await vm.loadDivisions() }
                }
            }
            .onChange(of: vm.currentDivision) { newValue in
                vm.changeDivision(newDivision: newValue)
            }
            
            ForEach(vm.holes) { hole in
                ZStack(alignment: .leading) {
                    THPostView(discussion: hole)
                    NavigationLink(destination: TreeHoleDetailsPage(holeId: hole.hole_id, initialFloors: hole.floors.prefetch)) {
                        EmptyView()
                    }
                }
            }
            
            if vm.endReached == false {
                ProgressView()
                    .task {
                        // Prevent duplicate refresh
                        if vm.currentDivision != OTDivision.dummy {
                            await vm.loadNextPage()
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
