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
    
    func loadHoles(token: JWToken, startTime: String?, divisionId: Int?) async throws -> [OTHole] {
        var components = URLComponents(string: BASE_URL + "/holes")!
        components.queryItems = [
            URLQueryItem(name: "start_time", value: startTime),
            URLQueryItem(name: "division_id", value: String(divisionId ?? 1))
        ]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([OTHole].self, from: data)
        return decodedResponse
    }
    
    func loadDivisions(token: JWToken)  async throws -> [OTDivision] {
        
        let components = URLComponents(string: BASE_URL + "/divisions")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([OTDivision].self, from: data)
        return decodedResponse
    }
    
    private func fetchHoles(token: JWToken) async -> [OTHole] {
        hasError = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await loadHoles(token: token,startTime: holes.last?.time_updated, divisionId: currentDivision.division_id)
        } catch {
            hasError = error
            return []
        }
    }
    
    func refresh(token: JWToken) async {
        endReached = false
        holes = currentDivision.pinned ?? []
        holes.append(contentsOf: await fetchHoles(token: token))
    }
    
    func loadNextPage(token: JWToken) async {
        let newData = await fetchHoles(token: token)
        guard !newData.isEmpty else {
            endReached = true
            return
        }
        holes.append(contentsOf: newData)
    }
    
    func changeDivision(token: JWToken, newDivision: OTDivision) {
        currentDivision = newDivision
        Task.init { await refresh(token: token) }
    }
    
    func fetchDivisions(token: JWToken) async -> Void {
        hasError = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            divisions = try await loadDivisions(token: token)
            if currentDivision == OTDivision.dummy {
                currentDivision = divisions.first ?? OTDivision.dummy
            }
            await refresh(token: token)
        } catch {
            hasError = error
        }
    }
}
