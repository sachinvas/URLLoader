//
//  URLLoader.swift
//  URLLoader
//
//  Created by Sachin Vas on 11/05/17.
//  Copyright © 2017 Sachin Vas. All rights reserved.
//

import Foundation

public typealias URLLoadCompletion = (Bool, Any?, Error?)->()

public enum DataType: String {
    case jpeg = "image/jpeg"
    case plain = "text/plain"
    case json = "application/json"
}

public protocol URLLoaderProtocol {
    func cancel()
}

public enum URLLoaderInitialisationError: Error {
    case invalidCostLimit(String)
    case invalidCountLimit(String)
}

public class URLLoader {
    
    public static let shared = URLLoader()
    public var totalCostLimit: Int = 0
    public var totalCountLimit: Int = 0
    internal var dataAccessor: DataAccessor!
        
    public func loadURL(_ urlString: String, completionBlock: @escaping URLLoadCompletion) throws -> URLLoaderProtocol? {
        if totalCostLimit == 0 {
            throw URLLoaderInitialisationError.invalidCostLimit("You need to set the value for cost limit to evict objects from cache")
        } else if totalCountLimit == 0 {
            throw URLLoaderInitialisationError.invalidCountLimit("You need to set the value for count limit to evict objects from cache")
        } else {
            if dataAccessor == nil {
                dataAccessor = DataAccessor("InMemoryCache", totalCostLimit: totalCostLimit, totalCountLimit: totalCountLimit)
            }
            return dataAccessor.getData(urlString, completionBlock:completionBlock)
        }
    }
}


