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
                if !vm.initialized && !vm.isLoading {
                    Task {
                        await vm.loadDivisions()
                        vm.initialized = true
                    }
                }
            }
            .onChange(of: vm.currentDivision) { newValue in
                vm.changeDivision(newDivision: newValue)
            }
            
            ForEach(vm.holes) { hole in
                GeometryReader { geometry in
                    NavigationLink(destination: TreeHoleDetailsPage(holeId: hole.hole_id, initialFloors: hole.floors.prefetch)) {
                        THPostView(hole: hole)
                            .padding()
                            .background(.white)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    }
                    .rotation3DEffect(Angle(degrees:
                                                Double(geometry.frame(in: .global).minX - 30) / -40), axis: (x: 0, y: 10.0, z: 0))
                }
                Spacer()
            }
            
            if vm.endReached == false {
                ProgressView()
                    .task {
                        // Prevent duplicate refresh
                        if vm.currentDivision != OTDivision.dummy && vm.initialized && !vm.isLoading {
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
