//
//  TreeHoleRepository.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import Foundation

let BASE_URL = "https://www.fduhole.tk/v1"

func loadDiscussions<T: Decodable>(_ page: Int, completion: @escaping (T) -> Void) -> Void {
    var components = URLComponents(string: BASE_URL + "/discussions/")!
    components.queryItems = [
        URLQueryItem(name: "page", value: String(page))
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Token YOUR_TOKEN", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
                // we have good data – go back to the main thread
                completion(decodedResponse)
                return
            }
        }
    }.resume()
}
