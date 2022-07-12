//
//  TreeHoleDetailsPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/1.
//

import SwiftUI

struct TreeHoleDetailsPage: View {
    let holeId: Int
    let initialFloors: [OTFloor]
    
    func loadData(page: Int, list: [OTFloor]) async throws -> [OTFloor] {
        return []
        //return try await TreeHoleRepository.shared.loadFloors(page: page, holeId: holeId)
    }
    
    var body: some View {
        PagedListView(headBuilder: {
            AnyView(EmptyView())
        }, viewBuilder: { floor in
            AnyView(
                ZStack(alignment: .leading) {
                    THPostDetailView(floor: floor)
                })
        }, initialData: initialFloors, dataLoader: loadData)
            .navigationTitle("#\(holeId)")
    }
}

struct TreeHoleDetailsPage_Previews: PreviewProvider {
    static var previews: some View {
        Text("too lazy to write preview")
    }
}
