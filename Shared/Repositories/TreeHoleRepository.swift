//
//  TreeHoleRepository.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import Foundation

let BASE_URL = "https://www.fduhole.tk/v1"

func getTokenHeader() -> String {
    return "Token 708d259cebb76d2b03aca46fc6a72c420e7aec73"
}

func loadDiscussions<T: Decodable>(page: Int, sortOrder: SortOrder) async throws -> T {
    var components = URLComponents(string: BASE_URL + "/discussions/")!
    components.queryItems = [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "order", value: sortOrder.getString())
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue(getTokenHeader(), forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        if ((response as? HTTPURLResponse)?.statusCode == 401) { throw TreeHoleError.unauthorized }
        throw TreeHoleError.connectionFailed
    }
    guard let decodedResponse = try? JSONDecoder().decode(T.self, from: data) else { throw TreeHoleError.invalidResponse }
    return decodedResponse
}

func loadReplies<T: Decodable>(page: Int, discussionId: Int) async throws -> T {
    var components = URLComponents(string: BASE_URL + "/posts/")!
    components.queryItems = [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "id", value: String(discussionId))
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue(getTokenHeader(), forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        if ((response as? HTTPURLResponse)?.statusCode == 401) { throw TreeHoleError.unauthorized }
        throw TreeHoleError.connectionFailed
    }
    guard let decodedResponse = try? JSONDecoder().decode(T.self, from: data) else { throw TreeHoleError.invalidResponse }
    return decodedResponse
}

enum TreeHoleError: Error {
    case insecureConnection
    case unauthorized
    case connectionFailed
    case invalidResponse
}

enum SortOrder {
    case last_updated
    case last_created
}

extension SortOrder {
    public func getString() -> String {
        switch (self) {
        case .last_created:
            return "last_created"
        case .last_updated:
            return "last_updated"
        }
    }
}
