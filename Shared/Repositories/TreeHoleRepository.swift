//
//  TreeHoleRepository.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import Foundation
import Alamofire
import SwiftUI

class TreeHoleRepository: ObservableObject {
    static let shared = TreeHoleRepository()
    
    func loginWithUsernamePassword(username:String, password: String) async throws -> JWToken {
        let response = await AF.request(BASE_URL + "/login", method: .post, parameters: ["email":username,"password":password], encoder: JSONParameterEncoder.default).serializingString().response.data
        let decodedResponse = try JSONDecoder().decode([JWToken].self, from: data)
        return decodedResponse
    }
    
    func loadHoles(startTime: String?, divisionId: Int?)  async throws -> [OTHole] {
        var components = URLComponents(string: BASE_URL + "/holes")!
        components.queryItems = [
            URLQueryItem(name: "start_time", value: startTime),
            URLQueryItem(name: "division_id", value: String(divisionId ?? 1))
        ]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        try request.setValue(getTokenHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([OTHole].self, from: data)
        return decodedResponse
    }
    
    func loadDivisions()  async throws -> [OTDivision] {
        guard token != nil else {
            throw TreeHoleError.notInitialized
        }
        
        let components = URLComponents(string: BASE_URL + "/divisions")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        try request.setValue(getTokenHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([OTDivision].self, from: data)
        return decodedResponse
    }
    
    func loadFloors(page: Int, holeId: Int)  async throws -> [OTFloor] {
        guard token != nil else {
            throw TreeHoleError.notInitialized
        }
        
        var components = URLComponents(string: BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "start_floor", value: String((page-1)*10)),
            URLQueryItem(name: "hole_id", value: String(holeId))
        ]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        try request.setValue(getTokenHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([OTFloor].self, from: data)
        return decodedResponse
    }
}


public enum TreeHoleError: LocalizedError {
    case unauthorized
    case notInitialized
    case serverReturnedError(message: String)
}

extension TreeHoleError {
    public var errorDescription: String? {
        switch self {
        case let .serverReturnedError(message):
            return message
        case .unauthorized:
            return "Unauthorized"
        case .notInitialized:
            return "Repository not initialized"
        }
    }
}
