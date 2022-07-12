//
//  TreeHolePageViewModel.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2022/3/9.
//

import Foundation

@MainActor
class TreeHolePageViewModel: ObservableObject {
    @Published var holes: [OTHole] = []
    @Published var divisions: [OTDivision] = []
    @Published var currentDivision: OTDivision = OTDivision.dummy
    
    @Published var endReached: Bool = false
    @Published var isLoading: Bool = false
    @Published var hasError: Error? = nil
    var initialized: Bool = false
    
    private func fetchHoles() async -> [OTHole] {
        hasError = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            return []
            //return try await TreeHoleRepository.shared.loadHoles(startTime: holes.last?.time_updated, divisionId: currentDivision.division_id)
        } catch {
            hasError = error
            return []
        }
    }
    
    func refresh() async {
        endReached = false
        holes = currentDivision.pinned ?? []
        holes.append(contentsOf: await fetchHoles())
    }
    
    func loadNextPage() async {
        let newData = await fetchHoles()
        guard !newData.isEmpty else {
            endReached = true
            return
        }
        holes.append(contentsOf: newData)
    }
    
    func changeDivision(newDivision: OTDivision) {
        currentDivision = newDivision
        Task.init { await refresh() }
    }
    
    func loadDivisions() async -> Void {
        hasError = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            divisions = []
            //divisions = try await TreeHoleRepository.shared.loadDivisions()
            if currentDivision == OTDivision.dummy {
                currentDivision = divisions.first ?? OTDivision.dummy
            }
            await refresh()
        } catch {
            hasError = error
        }
    }
}
