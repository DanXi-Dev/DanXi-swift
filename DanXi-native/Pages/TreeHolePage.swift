//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @State private var searchText: String = ""
    @State private var currentDivision: OTDivision = OTDivision.dummy
    @State private var divisions: [OTDivision] = [OTDivision.dummy]
    
    func loadData (page: Int, list: [OTHole]) async throws -> [OTHole] {
        return try await TreeHoleRepository.shared.loadHoles(startTime: list.last?.time_updated, divisionId: currentDivision.division_id)
    }
    
    
    func updateDivisions() async throws -> [OTDivision] {
        return try await TreeHoleRepository.shared.loadDivisions()
    }
    
    var body: some View {
        PagedListView(headBuilder: {
            AnyView(
                Picker("division", selection: $currentDivision) {
                    ForEach(divisions, id: \.self) {division in
                        Text("\(division.name) - \(division.description)")
                    }
                }
                    .task {
                        do {
                            divisions = try await updateDivisions()
                        } catch {}
                    }
                    .onChange(of: currentDivision) { newValue in
                    })
        }, viewBuilder: { hole in
            AnyView(
                ZStack(alignment: .leading) {
                    THPostView(discussion: hole)
                    NavigationLink(destination: TreeHoleDetailsPage(holeId: hole.hole_id, initialFloors: hole.floors.prefetch)) {
                        EmptyView()
                    }
                })
        }, dataLoader: loadData)
            .searchable(text: $searchText)
            .navigationTitle("treehole")
    }
    
    struct TreeHole_Previews: PreviewProvider {
        static var previews: some View {
            TreeHolePage()
        }
    }
}
