//
//  test.swift
//  DanXi Watch
//
//  Created by fsy2001 on 2023/11/4.
//

import Foundation

func test() {
    Task {
        let username = "23210240078"
        let password = "PFLMLpBpYqf07gZ"
        
        let url = URL(string: "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fecard.fudan.edu.cn%2Fepay%2Fj_spring_cas_security_check")!
        let request = prepareRequest(url)
        let (loginFormData, _) = try await URLSession.shared.data(for: request)
        
        print("---UIS Data---")
        printData(data: loginFormData)
        
        let authRequest = try FDAuthAPI.prepareAuthRequest(authURL: url, formData: loginFormData, username: username, password: password)
        
        let (data, response) = try await sendRequest(authRequest)
        print("---Response Data---")
        printData(data: data)
        
        print("---Response Info---")
        print("Response URL: \(response.url!.absoluteString)")
        let httpResponse = response as! HTTPURLResponse
        print("Response Code: \(httpResponse.statusCode)")
        print("---Send Info---")
        print("Request Method: \(authRequest.httpMethod!)")
        print("Request URL: \(authRequest.url!)")
        printData(data: authRequest.httpBody!)
        
    }
}

func printData(data: Data) {
    let string = String(data: data, encoding: String.Encoding.utf8)!
    print(string)
}
