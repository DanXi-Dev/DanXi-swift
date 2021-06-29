//
//  TreeHoleRepository.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import Foundation

let BASE_URL = "https://www.fduhole.tk/v1"


enum TreeHoleError: Error {
    case insecureConnection
    case unauthorized
    case connectionFailed
    case invalidResponse
}

func loadDiscussions<T: Decodable>(_ page: Int) async throws -> T {
    var components = URLComponents(string: BASE_URL + "/discussions/")!
    components.queryItems = [
        URLQueryItem(name: "page", value: String(page))
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Token 708d259cebb76d2b03aca46fc6a72c420e7aec73", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        if ((response as? HTTPURLResponse)?.statusCode == 401) { throw TreeHoleError.unauthorized }
        throw TreeHoleError.connectionFailed}
    
    guard let decodedResponse = try? JSONDecoder().decode(T.self, from: data) else { throw TreeHoleError.invalidResponse }
    return decodedResponse
}
