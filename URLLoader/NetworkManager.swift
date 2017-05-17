//
//  NetworkManager.swift
//  URLLoader
//
//  Created by Sachin Vas on 11/05/17.
//  Copyright © 2017 Sachin Vas. All rights reserved.
//

import Foundation

enum NetworkResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

class NetworkManager {
    
    static let shared = NetworkManager()
    
    func downloadContentOfURL(_ url: URL, completionBlock: @escaping (NetworkResult)->()) {
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            let genericError = NSError(domain: "com.URLLoader.networkError", code: 1001, userInfo: nil) as Error
            var networkResult = NetworkResult.failure(genericError)
            if let networkError = error {
                networkResult = .failure(networkError)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 209 {
                    networkResult = .success(data!, httpResponse)
                } else {
                    let error = NSError(domain: "com.URLLoader.networkError", code: httpResponse.statusCode, userInfo: nil) as Error
                    networkResult = .failure(error)
                }
            }
            completionBlock(networkResult)
        }
        dataTask.resume()
    }
}
