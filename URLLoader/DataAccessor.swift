//
//  DataAccessor.swift
//  URLLoader
//
//  Created by Sachin Vas on 11/05/17.
//  Copyright © 2017 Sachin Vas. All rights reserved.
//

import Foundation

class DataAccessor: URLLoadProtocol {
    
    private var cache: Cache
    private var urlLoadQueue: OperationQueue
    private var loads = [URLLoad]()
    
    init(_ name: String, totalCostLimit: Int, totalCountLimit: Int) {
        urlLoadQueue = OperationQueue()
        urlLoadQueue.name = "com.URLLoader.urlLoaderQueue"
        urlLoadQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        urlLoadQueue.qualityOfService = .utility
        cache = Cache(name, totalCostLimit: totalCostLimit, totalCountLimit: totalCountLimit)
    }
    
    func getData(_ urlString: String, completionBlock: @escaping URLLoadCompletion) -> URLLoaderProtocol? {
        if let value = cache[urlString] {
            completionBlock(true, value, nil)
            return nil
        } else {
            let existingLoads = loads.filter({$0.urlOperation.loadURLString == urlString})
            var urlOperation: URLLoadOperation
            var isAdded = false
            if existingLoads.count > 0 {
                urlOperation = existingLoads[0].urlOperation
            } else {
                urlOperation = URLLoadOperation(urlString)
                isAdded = true
            }
            let urlLoad = URLLoad(urlOperation, completionBlock: completionBlock)
            loads.append(urlLoad)
            urlLoad.delegate = self
            if isAdded {
                urlLoadQueue.addOperation(urlOperation)
            }
            return urlLoad
        }
    }

    func load(_ load: URLLoad, didCancelLoading cancelled: Bool) {
        if cancelled {
            if let existingLoadIndex = loads.index(where: {$0 === load}) {
                loads.remove(at: existingLoadIndex)
            }
        }
    }
    
    func load(_ load: URLLoad, didComplete complete: (Bool, (Data, String)?, Error?)) {
        if cache[load.urlOperation.loadURLString] == nil {
            if let downloadedEntry = complete.1 {
                let entry = (downloadedEntry.0, DataType(rawValue: downloadedEntry.1)!)
                cache.setObject(entry, forKey: load.urlOperation.loadURLString, cost: downloadedEntry.0.count)
            }
        }
        if let value = cache[load.urlOperation.loadURLString] {
            load.completionBlock?(true, value, nil)
        }
    }
}
